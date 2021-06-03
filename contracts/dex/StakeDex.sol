// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/Math.sol";


contract StakeDex {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    uint public pairId = 0;
    uint public AMP = 1e18;

    struct Liquidity {
        uint256 price;
        uint256 pending;
        uint256 filled;
        uint256 feeRewarded;
    }

    struct Depth {
        uint256 price;
        uint256 amount;
    }

    struct Rate {
        uint256 traded;
        uint256 fee;
    }

    Rate public HEAD = Rate({
        traded: uint256(-1),
        fee: 0
    });

    Rate public ZERO = Rate({
        traded: 0,
        fee: 0
    });

    // token0 => token1 => id
    mapping (address => mapping (address => uint)) public pairs;
    // id => decimal
    mapping (uint => int8) public decimals;
    // id => [ prices ]
    mapping (uint => uint256[]) public prices;
    // id => price => amount
    mapping (uint => mapping (uint => uint)) public depth;
    // id => price => rate
    mapping (uint => mapping (uint => Rate[])) public tradedRateStored;

    int8 public defaultDecimals = 8;

    address public feeTo;
    address public gov;

    uint public feeForTake = 20; // 0.2% 
    uint public feeForProvide = 10; // 0.10% to makers
    uint public feeForReserve = 10; // 0.10% reserved

    uint256 public amountInMin = 500000;  // base is 10000
    uint256 public amountInMax = 10000000; // base is 10000



    // user => id => price => amount
    mapping (address => mapping (uint => mapping (uint => uint))) public userOrders;
    // user => id => price => rate
    mapping (address => mapping (uint => mapping (uint => uint))) public userRateRedeemed;


    // rewards
    IERC20 public rewardToken;

    // eg. USDT => BUSD -> 1e16(0.01) / BUSD => USDT -> 1e16(0.01)
    mapping (address => mapping (address => uint256)) public miningRate;
    
    uint256 public makerReservedRewards;



    event AddLiquidity(address indexed sender, address tokenIn, address tokenOut, uint price, uint amountIn, uint date);
    event RemoveLiquidity(address indexed sender, address tokenIn, address tokenOut, uint price, uint amountReturn, uint date);
    event Swap(address indexed sender, address tokenIn, address tokenOut, uint amountIn, uint amountOut, uint date);
    event Redeem(address indexed sender, address tokenIn, address tokenOut, uint price, uint filled, uint date);
    event CreatePair(address indexed token0, address indexed token1, uint date);

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }
    modifier onlyGov() { 
        require(gov == msg.sender, "Not gov");
        _; 
    }
    

    constructor(address feeTo_) public {
        gov = msg.sender;
        feeTo = feeTo_;
    }

    function updateDefaultDecimals(int8 decimals_) public onlyGov {
        defaultDecimals = decimals_;
    }

    function setRewardToken(address token_) public onlyGov {
        rewardToken = IERC20(token_);
    }


    function setFees(uint256 take_, uint256 provide_, uint256 reserve_) public onlyGov {
        require(take_ == provide_.add(reserve_), "take_ != provide_ + reserve_");
        feeForTake = take_;
        feeForProvide = provide_;
        feeForReserve = reserve_;
    }

    function setMiningRate(address tokenA, address tokenB, uint256 rate) public onlyGov {
        miningRate[tokenA][tokenB] = rate;
        miningRate[tokenB][tokenA] = rate;
    }

    function setAmountInLimit(uint256 min_, uint256 max_) public onlyGov {
        amountInMin = min_;
        amountInMax = max_;
    }

    function distributeTradeRewardToTaker(address tokenIn, address tokenOut, uint256 amountIn, address taker) internal {
        if(address(rewardToken) == address(0x0)) {
            return;
        }

        uint256 freeBalance = rewardToken.balanceOf(address(this)).sub(makerReservedRewards);

        if(freeBalance == 0) {
            return;
        }
        uint256 exp = 10 ** uint256(ERC20(tokenIn).decimals());
        uint256 reward = amountIn.mul(miningRate[tokenIn][tokenOut]).div(exp).div(1e18);

        if(reward == 0) {
            return;
        }

        if(reward > freeBalance) {
            reward = freeBalance;
        }

        uint256 toMaker = reward.mul(30).div(100); // 30% to maker
        uint256 toTaker = reward.sub(toMaker);// 70% to taker
        makerReservedRewards = makerReservedRewards.add(toMaker);
        rewardToken.transfer(taker, toTaker);
        rewardToken.transfer(feeTo, reward.div(10)); // 1/10 to dev
    }

    function distributeTradeRewardToMaker(address tokenIn, address tokenOut , uint256 amountOut, address maker) internal {
        if(address(rewardToken) == address(0x0)) {
            return;
        }

        uint256 exp = 10 ** uint256(ERC20(tokenOut).decimals());
        uint256 reward = amountOut.mul(miningRate[tokenOut][tokenIn]).div(exp).div(1e18);

        if(reward == 0) {
            return;
        }

        uint256 toMaker = reward.mul(30).div(100); // 30% to maker
        uint256 freeBalance = rewardToken.balanceOf(address(this));

        if(freeBalance == 0) {
            return;
        }

        if(toMaker > freeBalance) {
            rewardToken.transfer(maker, freeBalance);    
        } else {
            rewardToken.transfer(maker, toMaker);
        }
    }

    // withdraw reward tokens in case of migration
    function migrateRewardToken(address to_) public onlyGov {
        uint256 bal = rewardToken.balanceOf(address(this));
        rewardToken.transfer(to_, bal);
    }


    function createPair(address tokenA, address tokenB) public {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        if(pairs[token0][token1] == 0) {
            pairId += 1;
            pairs[token0][token1] = pairId;
        }
        if(pairs[token1][token0] == 0) {
            pairId += 1;
            pairs[token1][token0] = pairId;
        }
        
        setPairDecimals(tokenA, tokenB, defaultDecimals);

        emit CreatePair(token0, token1, now);
    }

    function updatePairDecimals(address tokenA, address tokenB, int8 decimals_) public {
        require(gov == msg.sender, "Not gov");
        setPairDecimals(tokenA, tokenB, decimals_);
    }

    function setPairDecimals(address tokenA, address tokenB, int8 decimals_) internal {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        int8 dec01 = int8(decimals_) + int8(ERC20(token0).decimals()) - int8(ERC20(token1).decimals());
        int8 dec10 = int8(decimals_) + int8(ERC20(token1).decimals()) - int8(ERC20(token0).decimals());

        decimals[pairs[token0][token1]] = dec01;
        decimals[pairs[token1][token0]] = dec10;
    }


    function getPrices(address tokenIn, address tokenOut) public view returns(uint[] memory) {
        uint id = getPairId(tokenIn, tokenOut);
        return prices[id];
    }

    function getDepth(address tokenIn, address tokenOut) public view returns(Depth[] memory) {
        uint id = getPairId(tokenIn, tokenOut);
        Depth[] memory depths = new Depth[](prices[id].length);
        for(uint256 i = 0; i < prices[id].length; i++) {
            depths[i] = Depth({
                price: prices[id][i],
                amount: depth[id][prices[id][i]]
            });
        }
        return depths;
    }

    function getTradedRates(uint256 id, uint256 price) public view returns(Rate[] memory) {
        return tradedRateStored[id][price];
    }

    function getPairId(address tokenIn, address tokenOut) public view returns(uint) {
        return pairs[tokenIn][tokenOut];
    }


    function fetchPairId(address tokenIn, address tokenOut) public view returns(uint256) {
        uint id = getPairId(tokenIn, tokenOut);
        require(id > 0, "Not exists");
        return id;
    }

    function removeLiquidity(
        address tokenIn,
        address tokenOut,
        uint256 price
    ) public lock
    {
        uint id = fetchPairId(tokenIn, tokenOut);
        if(userOrders[msg.sender][id][price] > 0) {
            redeemTraded(msg.sender, tokenIn, tokenOut, price);    
        }

        uint amountOut = userOrders[msg.sender][id][price];
        require(amountOut > 0, "No Liquidity");

        if(depth[id][price] >= amountOut) {
            depth[id][price] = depth[id][price].sub(amountOut);
            userOrders[msg.sender][id][price] = 0;
        } else {
            // require(amountOut.sub(depth[id][price]) <= 100, "Insufficient Depth");
            amountOut = depth[id][price];
            depth[id][price] = 0;
            userOrders[msg.sender][id][price] = 0;
        }

        uint amountReturn = getAmountOut(id, amountOut, price);
        if(amountReturn > 0) {
            IERC20(tokenIn).transfer(msg.sender, amountReturn);    
        }

        emit RemoveLiquidity(msg.sender, tokenIn, tokenOut, price, amountReturn, now);

        // if(depth[id][price] == 0) {
        //     skimPriceArray(tokenIn, tokenOut);
        // }
    }

    function calcAmountInLimit(address token) public view returns(uint256 min, uint256 max) {
        uint256 dec = uint256(ERC20(token).decimals());
        min = amountInMin.mul(10 ** dec).div(10000);
        max = amountInMax.mul(10 ** dec).div(10000);
    }

    function addLiquidity(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    ) public lock
    {   
        require(amountIn > 0 && amountOut > 0, "ZERO");
        (uint256 min, uint256 max) = calcAmountInLimit(tokenIn);
        require(amountIn >= min && amountIn <= max,  "Exceeds Limit");

        if(getPairId(tokenIn, tokenOut) == 0) {
            createPair(tokenIn, tokenOut);
        }

        uint id = fetchPairId(tokenIn, tokenOut);

        int8 exp = decimals[id];

        uint256 price;

        if(exp > 0) {
            price = amountOut.mul(10 ** uint(exp)).div(amountIn);
            amountOut = price.mul(amountIn).div(10 ** uint(exp));
        } else {
            price = amountOut.div(10 ** uint(-exp)).div(amountIn);
            amountOut = price.mul(amountIn).mul(10 ** uint(-exp));
        }

        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);

        if(userOrders[msg.sender][id][price] > 0) {
            redeemTraded(msg.sender, tokenIn, tokenOut, price);
        }

        depth[id][price] = depth[id][price].add(amountOut);
        userOrders[msg.sender][id][price] = userOrders[msg.sender][id][price].add(amountOut);

        addToPriceArray(tokenIn, tokenOut, price);

        if (tradedRateStored[id][price].length == 0) {
            tradedRateStored[id][price].push(HEAD);
        }
        uint256 size = tradedRateStored[id][price].length;
        if(tradedRateStored[id][price][size - 1].traded == 0) {
            userRateRedeemed[msg.sender][id][price] = size - 1;
        } else {
            tradedRateStored[id][price].push(ZERO);
            userRateRedeemed[msg.sender][id][price] = size;
        }

        emit AddLiquidity(msg.sender, tokenIn, tokenOut, price, amountIn, now);
    }

    function addToPriceArray(address tokenIn, address tokenOut, uint256 price) internal {
        uint id = getPairId(tokenIn, tokenOut);
        uint256[] storage priceArray = prices[id];

        if(priceArray.length == 0) {
            priceArray.push(price);
            return;
        }
        // priceArray.push();
        uint256 i = 0;
        uint256 len = priceArray.length;
        bool pushed = false;
        while(i < len) {
            if(priceArray[i] > price) {
                priceArray.push();
                for(uint256 j = len; j > i; j--) {
                    priceArray[j] = priceArray[j - 1];
                }
                priceArray[i] = price;
                pushed = true;
                break;
            } else if (price == priceArray[i]) {
                pushed = true;
                break;
            } else {
                i = i + 1;
            }
        }

        if(!pushed) {
            priceArray.push(price);
            // priceArray[len - 1] = price;
        }
    }

    function skimPriceArray(
        address tokenIn, 
        address tokenOut
    ) internal 
    {
        uint id = getPairId(tokenIn, tokenOut);
        uint256[] storage priceArray = prices[id];

        if(priceArray.length == 0) {
            return;
        }

        if(priceArray.length == 1) {
            if(depth[id][priceArray[0]] == 0) {
                priceArray.pop();
            }
            return;
        }

        uint256 i = 0;
        uint256 len = priceArray.length;

        while(i < len) {
            uint256 price = priceArray[i];
            if(depth[id][price] == 0) {
                for(uint256 j = i; j < len - 1; j++) {
                    priceArray[j] = priceArray[j + 1];
                }
                priceArray.pop();
                len = len - 1;
            }
            i++;
        }
    }
    function calcRate(uint256 currentRate, uint256 storedRate) public view returns(uint256) {
        return uint(AMP).sub(storedRate).mul(currentRate).div(AMP);
    }


    function redeemTraded(
        address account, 
        address tokenIn, 
        address tokenOut, 
        uint256 price
    ) internal returns(uint256 pending, uint256 filled) 
    {
        uint id = fetchPairId(tokenIn, tokenOut);
        pending = userOrders[account][id][price];

        require(pending > 0, "No Liquidity");

        Rate[] storage rates = tradedRateStored[id][price];

        uint256 accumlatedRate = 0;
        uint256 accumlatedRateFee = 0;
        uint256 startIndex = userRateRedeemed[account][id][price];


        for(uint256 i = startIndex; i < rates.length; i++) {
            accumlatedRateFee += calcRate(rates[i].fee, i == startIndex ? 0 : rates[i - 1].traded);
            accumlatedRate += calcRate(rates[i].traded, i == startIndex ? 0 : rates[i - 1].traded);
            if(rates[i].traded == AMP) {
                break;    
            }
        }
        filled = pending.mul(accumlatedRate).div(AMP);
        // uint256 fee = pending.mul(accumlatedRateFee).div(AMP);
        if(filled > 0) {
            IERC20(tokenOut).transfer(account, filled.add(pending.mul(accumlatedRateFee).div(AMP)));
            userOrders[account][id][price] = pending.sub(filled);
            emit Redeem(account, tokenIn, tokenOut, price, filled, now);

            distributeTradeRewardToMaker(tokenOut, tokenIn, filled, account);
        }
    }

    function getLiquidity(
        address account, 
        address tokenIn, 
        address tokenOut, 
        uint256 price
    ) public view returns(uint256 feeRewarded, uint256 filled, uint256 pending) {
        uint id = fetchPairId(tokenIn, tokenOut);
        pending = userOrders[account][id][price];

        if(pending == 0) {
            return (0, 0, 0);
        }

        Rate[] memory rates = tradedRateStored[id][price];

        uint256 accumlatedRate = 0;
        uint256 accumlatedRateFee = 0;
        uint256 startIndex = userRateRedeemed[account][id][price];

        for(uint256 i = startIndex; i < rates.length; i++) {
            accumlatedRateFee += calcRate(rates[i].fee, i == startIndex ? 0 : rates[i - 1].traded);
            accumlatedRate += calcRate(rates[i].traded, i == startIndex ? 0 : rates[i - 1].traded);
            if(rates[i].traded == AMP) {
                break;
            }
        }
        filled = pending.mul(accumlatedRate).div(AMP);
        feeRewarded = pending.mul(accumlatedRateFee).div(AMP);
        pending = pending.sub(filled);
    }

    function getAllLiquidities(
        address account, 
        address tokenIn, 
        address tokenOut
    ) public view returns(Liquidity[] memory) {
        uint id = getPairId(tokenIn, tokenOut);
        Liquidity[] memory liquids = new Liquidity[](prices[id].length);
        for(uint256 i = 0; i < prices[id].length; i++) {
            (uint256 feeRewarded, uint256 filled, uint256 pending) = getLiquidity(account, tokenIn, tokenOut, prices[id][i]);
            if(feeRewarded == 0 && filled == 0 && pending == 0) {
                continue;
            }
            liquids[i] = Liquidity({
                price: prices[id][i],
                pending: pending,
                filled: filled,
                feeRewarded: feeRewarded
            });
        }
        return liquids;
    }


    function redeem(address tokenIn, address tokenOut, uint256 price) public lock {
        uint id = fetchPairId(tokenIn, tokenOut);
        redeemTraded(msg.sender, tokenIn, tokenOut, price);


        uint256 size = tradedRateStored[id][price].length;

        if(tradedRateStored[id][price][size - 1].traded == 0) {
            userRateRedeemed[msg.sender][id][price] = size - 1;
        } else {
            tradedRateStored[id][price].push(ZERO);
            userRateRedeemed[msg.sender][id][price] = size;
        }
    }

    function swap(
        address tokenIn, 
        address tokenOut, 
        uint amountIn, 
        uint amountOutMin,
        address to
    ) public returns(uint256 amountOut)
    {   
        uint id = fetchPairId(tokenOut, tokenIn);
        uint total = amountIn;
        uint totalFee = 0;

        for(uint256 i = 0; i < prices[id].length; i++) {
            uint256 p = prices[id][i];
            if(depth[id][p] == 0) {
                continue;
            }
            (uint _amountReturn, uint _amountOut, uint _reserveFee, uint _pending) = _swapWithFixedPrice(id, depth[id][p], amountIn, p);

            totalFee = totalFee.add(_reserveFee);
            amountOut = amountOut.add(_amountOut);
            amountIn = _amountReturn;
            depth[id][p] = _pending;

            if(amountIn == 0) {
                break;
            }
        }
        require(amountOut >= amountOutMin && amountOut > 0, "INSUFFICIENT_OUT_AMOUNT");

        IERC20(tokenIn).transferFrom(msg.sender, address(this), total.sub(amountIn));
        IERC20(tokenIn).transfer(feeTo, totalFee);
        IERC20(tokenOut).transfer(msg.sender, amountOut);

        distributeTradeRewardToTaker(tokenIn, tokenOut, total.sub(amountIn), to);
        emit Swap(msg.sender, tokenIn, tokenOut, amountIn, amountOut, now);
    }


    function _swapWithFixedPrice(
        uint id,
        uint amountPending,
        uint amountIn, 
        uint price
    ) internal returns(uint /*amountReturn*/, uint amountOut, uint reserveFee, uint /*pending*/) {

        uint takeFee = amountPending.mul(feeForTake).div(10000);
        uint256 rateTrade;
        uint256 rateFee;
        
        if(amountIn >= amountPending.add(takeFee)) {
            reserveFee = amountPending.mul(feeForReserve).div(10000);

            rateTrade = AMP;
            rateFee = takeFee.sub(reserveFee).mul(AMP).div(amountPending);

            amountOut += getAmountOut(id, amountPending, price);

            amountIn = amountIn.sub(amountPending).sub(takeFee);
            amountPending = 0;
        } else {
            takeFee = amountIn.mul(feeForTake).div(10000);
            reserveFee = amountIn.mul(feeForReserve).div(10000);

            rateTrade = amountIn.sub(takeFee).mul(AMP).div(amountPending);
            rateFee = takeFee.sub(reserveFee).mul(AMP).div(amountPending);


            amountOut += getAmountOut(id, amountIn.sub(takeFee), price);

            amountPending = amountPending.sub(amountIn.sub(takeFee));
            amountIn = 0;
        }

        Rate storage rate = tradedRateStored[id][price][tradedRateStored[id][price].length - 1];

        rate.fee += calcRate(rateFee, rate.traded);
        rate.traded += calcRate(rateTrade, rate.traded);

        return (amountIn, amountOut, reserveFee, amountPending);
    }

    

    function getAmountOut(uint256 id, uint256 amountIn, uint256 price) public view returns(uint256) {
        int8 exp = decimals[id];
        if(exp > 0) {
            return amountIn.mul(10 ** uint(exp)).div(price);
        } else {
            return amountIn.div(10 ** uint(-exp)).div(price);
        }
    }

    function getAmountIn(uint256 id, uint256 amountOut, uint256 price) public view returns(uint256) {
        int8 exp = decimals[id];
        if(exp > 0) {
            return amountOut.mul(price).div(10 ** uint(exp));
        } else {
            return amountOut.mul(price).mul(10 ** uint(-exp));
        }
    }

    function calcInAmount(
        address tokenIn, 
        address tokenOut, 
        uint amountOut
    ) public view returns(uint256 amountIn, uint256 amountReturn) {
        uint id = fetchPairId(tokenOut, tokenIn);

        for(uint256 i = 0; i < prices[id].length; i++) {
            uint256 p = prices[id][i];
            if(depth[id][p] == 0) {
                continue;
            }

            uint256 amountWithFee = getAmountIn(id, amountOut, p).mul(10000 + feeForTake).div(10000);

            if(amountWithFee > depth[id][p]) {
                amountIn += depth[id][p].mul(10000 + feeForTake).div(10000);
                amountOut = amountOut.sub(getAmountOut(id, depth[id][p], p));
            } else {
                amountIn += getAmountIn(id, amountOut, p).mul(10000 + feeForTake).div(10000);
                amountOut = 0;
            }
        }
        amountReturn = amountOut;
    }

    function calcOutAmount(
        address tokenIn, 
        address tokenOut, 
        uint amountIn
    ) public view returns(uint256 amountOut, uint256 amountReturn) 
    {
        uint id = fetchPairId(tokenOut, tokenIn);

        for(uint256 i = 0; i < prices[id].length; i++) {
            uint256 p = prices[id][i];
            if(depth[id][p] == 0) {
                continue;
            }

            uint256 amountWithFee = depth[id][p].add(depth[id][p].mul(feeForTake).div(10000));

            if(amountIn >= amountWithFee) {
                // amountOut += depth[id][p].mul(1e18).div(p);
                amountOut += getAmountOut(id, depth[id][p], p);
                amountIn = amountIn.sub(amountWithFee);
            } else {
                uint256 fee = amountIn.mul(feeForTake).div(10000);
                // amountOut += amountIn.sub(fee).mul(1e18).div(p);
                amountOut += getAmountOut(id, amountIn.sub(fee), p);
                amountIn = 0;
                break;
            }
        }

        amountReturn = amountIn;
    }
}