// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./IERC20.sol";


contract StakeDex {
    using SafeMath for uint256;

    uint public AMP = 1e18;

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


    struct Pair {
        uint256 id;
        int8 decimals;
        uint256[] prices;
        // price => amount
        mapping (uint256 => uint256) depth;
        // price => Rate[]
        mapping (uint256 => Rate[]) tradedRateStored;
    }

    mapping (uint256 => Pair) public getPair;
    mapping (address => mapping (address => uint)) public getPairId;
    
    int8 public defaultDecimals = 8;

    address public feeTo;
    address public gov;

    uint public feeForTake = 20; // 0.2% 
    uint public feeForProvide = 12; // 0.10% to makers
    uint public feeForReserve = 8; // 0.10% reserved

    // uint256 public amountInMin = 0; //500000;  // base is 10000
    // uint256 public amountInMax = 10000000; // base is 10000

    struct Order {
        uint256 pendingOut;
        uint256 rateRedeemedIndex;
    }

    // user => id => price => Order
    mapping (address => mapping (uint256 => mapping (uint256 => Order))) public userOrders;
    

    mapping (address => uint256) public reserves;
    

    event AddLiquidity(address indexed sender, address tokenIn, address tokenOut, uint price, uint amountIn);
    event RemoveLiquidity(address indexed sender, address tokenIn, address tokenOut, uint price, uint amountReturn);
    event Swap(address indexed sender, address tokenIn, address tokenOut, uint amountIn, uint amountOut);
    event Redeem(address indexed sender, address tokenIn, address tokenOut, uint price, uint filled);
    event CreatePair(address indexed token0, address indexed token1, uint256 id);

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

    function setFees(uint256 take_, uint256 provide_, uint256 reserve_) public onlyGov {
        require(take_ == provide_.add(reserve_), "take_ != provide_ + reserve_");
        feeForTake = take_;
        feeForProvide = provide_;
        feeForReserve = reserve_;
    }

    function setAmountInLimit(uint256 min_, uint256 max_) public onlyGov {
        amountInMin = min_;
        amountInMax = max_;
    }
    
    function createPair(address tokenIn, address tokenOut) public {
        getPairId[tokenIn][tokenOut] += 1;

        uint256 id = getPairId[tokenIn][tokenOut];

        int8 decimals = int8(defaultDecimals) + int8(IERC20(tokenIn).decimals()) - int8(IERC20(tokenOut).decimals());

        Pair storage pair = getPair[id];
        pair.id = id;
        pair.decimals = decimals;

        emit CreatePair(tokenIn, tokenOut, id);
    }

    function updatePairDecimals(address tokenIn, address tokenOut, int8 decimals_) public {
        require(gov == msg.sender, "Not gov");
        getPair[getPairId[tokenIn][tokenOut]].decimals = int8(decimals_) + int8(IERC20(tokenIn).decimals()) - int8(IERC20(tokenOut).decimals());
    }

    function removeLiquidity(
        address tokenIn,
        address tokenOut,
        uint256 price
    ) public lock
    {
        uint256 id = getPairId[tokenIn][tokenOut];
        Pair storage pair = getPair[id];
        Order storage order = userOrders[msg.sender][id][price];

        uint256 amountOut = order.pendingOut;

        if(amountOut > 0) {
            redeemTraded(msg.sender, tokenIn, tokenOut, price);    
        }
        require(amountOut > 0, "No Liquidity");


        if(pair.depth[price] >= amountOut) {
            pair.depth[price] = pair.depth[price].sub(amountOut);
            order.pendingOut = 0;
        } else {
            // require(amountOut.sub(depth[id][price]) <= 100, "Insufficient Depth");
            amountOut = pair.depth[price];
            pair.depth[price] = 0;
            order.pendingOut = 0;
        }

        uint256 amountReturn = getAmountOut(id, amountOut, price);
        if(amountReturn > 0) {
            IERC20(tokenIn).transfer(msg.sender, amountReturn);

            _update(tokenIn);
        }

        emit RemoveLiquidity(msg.sender, tokenIn, tokenOut, price, amountReturn);

        // if(depth[id][price] == 0) {`
        //     skimPriceArray(tokenIn, tokenOut);
        // }
    }

    // function calcAmountInLimit(address token) public view returns(uint256 min, uint256 max) {
    //     uint256 dec = uint256(IERC20(token).decimals());
    //     min = amountInMin.mul(10 ** dec).div(10000);
    //     max = amountInMax.mul(10 ** dec).div(10000);
    // }

    function _update(address token) internal {
        reserves[token] = IERC20(token).balanceOf(address(this));
    }

    function _transferFrom(address token, address from, uint256 amount) internal returns(uint256) {
        uint256 beforeBalance = IERC20(token).balanceOf(address(this));
        IERC20(token).transferFrom(from, address(this), amount);
        uint256 afterBalance = IERC20(token).balanceOf(address(this));
        return afterBalance.sub(beforeBalance);
    }

    function addLiquidity(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    ) public lock
    {   
        require(amountIn > 0 && amountOut > 0, "ZERO");

        if(getPairId[tokenIn][tokenOut] == 0) {
            createPair(tokenIn, tokenOut);
        }
        uint256 id = getPairId[tokenIn][tokenOut];
        Pair storage pair = getPair[id];

        amountIn = _transferFrom(tokenIn, msg.sender, amountIn);

        uint256 price;

        if(pair.decimals > 0) {
            price = amountOut.mul(10 ** uint(pair.decimals)).div(amountIn);
            amountOut = price.mul(amountIn).div(10 ** uint(pair.decimals));
        } else {
            price = amountOut.div(10 ** uint(-pair.decimals)).div(amountIn);
            amountOut = price.mul(amountIn).mul(10 ** uint(-pair.decimals));
        }

        // if(userOrders[msg.sender][id][price] > 0) {
        //     redeemTraded(msg.sender, tokenIn, tokenOut, price);
        // }

        pair.depth[price] = pair.depth[price].add(amountOut); 

        // depth[id][price] = depth[id][price].add(amountOut);
        // userOrders[msg.sender][id][price] = userOrders[msg.sender][id][price].add(amountOut);

        Order storage order = userOrders[msg.sender][id][price];
        order.pendingOut = order.pendingOut.add(amountOut);


        addToPriceArray(tokenIn, tokenOut, price);

        if(pair.tradedRateStored[price].length == 0) {
            pair.tradedRateStored[price].push(HEAD);
        }

        uint256 size = pair.tradedRateStored[price].length;
        if(pair.tradedRateStored[price][size - 1].traded == 0) {
            // userRateRedeemed[msg.sender][id][price] = size - 1;
            order.rateRedeemedIndex = size - 1;
        } else {
            pair.tradedRateStored[price].push(ZERO);
            // userRateRedeemed[msg.sender][id][price] = size;
            order.rateRedeemedIndex = size;
        }



        // if (tradedRateStored[id][price].length == 0) {
        //     tradedRateStored[id][price].push(HEAD);
        // }
        // uint256 size = tradedRateStored[id][price].length;
        // if(tradedRateStored[id][price][size - 1].traded == 0) {
        //     userRateRedeemed[msg.sender][id][price] = size - 1;
        // } else {
        //     tradedRateStored[id][price].push(ZERO);
        //     userRateRedeemed[msg.sender][id][price] = size;
        // }

        _update(tokenIn);

        emit AddLiquidity(msg.sender, tokenIn, tokenOut, price, amountIn);
    }

    function addToPriceArray(address tokenIn, address tokenOut, uint256 price) internal {
        uint id = getPairId[tokenIn][tokenOut];
        uint256[] storage priceArray = getPair[id].prices;

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
        uint id = getPairId[tokenIn][tokenOut];
        Pair storage pair = getPair[id];
        uint256[] storage priceArray = pair.prices;

        if(priceArray.length == 0) {
            return;
        }

        if(priceArray.length == 1) {
            if(pair.depth[priceArray[0]] == 0) {
                priceArray.pop();
            }
            return;
        }

        uint256 i = 0;
        uint256 len = priceArray.length;

        while(i < len) {
            uint256 price = priceArray[i];
            if(pair.depth[price] == 0) {
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
    ) internal
    {
        uint id = getPairId[tokenIn][tokenOut];
        Pair storage pair = getPair[id];
        Order storage order = userOrders[account][id][price];

        require(order.pendingOut > 0, "No Liquidity");

        Rate[] storage rates = pair.tradedRateStored[price];

        uint256 accumlatedRate = 0;
        uint256 accumlatedRateFee = 0;
        uint256 startIndex = order.rateRedeemedIndex;


        for(uint256 i = startIndex; i < rates.length; i++) {
            accumlatedRateFee += calcRate(rates[i].fee, i == startIndex ? 0 : rates[i - 1].traded);
            accumlatedRate += calcRate(rates[i].traded, i == startIndex ? 0 : rates[i - 1].traded);
            if(rates[i].traded == AMP) {
                break;
            }
        }
        uint256 filled = order.pendingOut.mul(accumlatedRate).div(AMP);
        uint256 fee = order.pendingOut.mul(accumlatedRateFee).div(AMP);
        if(filled > 0) {
            IERC20(tokenOut).transfer(account, filled.add(fee));
            order.pendingOut = order.pendingOut.sub(filled);

            _update(tokenOut);

            emit Redeem(account, tokenIn, tokenOut, price, filled);
        }
    }

    function redeem(address tokenIn, address tokenOut, uint256 price) public lock {
        uint id = getPairId[tokenIn][tokenOut];
        redeemTraded(msg.sender, tokenIn, tokenOut, price);

        Pair storage pair = getPair[id];
        uint256 size = pair.tradedRateStored[price].length;

        if(pair.tradedRateStored[price][size - 1].traded == 0) {
            userOrders[msg.sender][id][price].rateRedeemedIndex = size - 1;
        } else {
            pair.tradedRateStored[price].push(ZERO);
            userOrders[msg.sender][id][price].rateRedeemedIndex = size;
        }
    }

    function swap(
        address tokenIn, 
        address tokenOut, 
        uint amountOutMin,
        address to
    ) public returns(uint256 amountOut)
    {   
        uint id = getPairId[tokenOut][tokenIn];

        Pair storage pair = getPair[id];

        uint256 amountIn = IERC20(tokenIn).balanceOf(address(this)).sub(reserves[tokenIn]);

        uint total = amountIn;
        uint totalFee = 0;

        for(uint256 i = 0; i < pair.prices.length; i++) {
            uint256 p = pair.prices[i];

            if(pair.depth[p] == 0) {
                continue;
            }
            (uint _amountReturn, uint _amountOut, uint _reserveFee) = _swapWithFixedPrice(id, amountIn, p);

            totalFee = totalFee.add(_reserveFee);
            amountOut = amountOut.add(_amountOut);
            amountIn = _amountReturn;

            if(amountIn == 0) {
                break;
            }
        }
        require(amountOut >= amountOutMin && amountOut > 0, "INSUFFICIENT_OUT_AMOUNT");

        if(amountIn > 0) {
            IERC20(tokenIn).transfer(to, amountIn); // refund
        }

        // IERC20(tokenIn).transferFrom(msg.sender, address(this), total.sub(amountIn));
        IERC20(tokenIn).transfer(feeTo, totalFee);
        // IERC20(tokenOut).transfer(msg.sender, amountOut);
        if(to != address(this)) {
            IERC20(tokenOut).transfer(to, amountOut);
        }

        reserves[tokenOut] = reserves[tokenOut].sub(amountOut);
        _update(tokenIn);

        emit Swap(msg.sender, tokenIn, tokenOut, total.sub(amountIn), amountOut);
    }


    function _swapWithFixedPrice(
        uint id,
        uint amountIn, 
        uint price
    ) internal returns(uint /*amountReturn*/, uint amountOut, uint reserveFee) {
        Pair storage pair = getPair[id];

        uint takeFee = pair.depth[price].mul(feeForTake).div(10000);
        uint256 rateTrade;
        uint256 rateFee;
        
        if(amountIn >= pair.depth[price].add(takeFee)) {
            reserveFee = pair.depth[price].mul(feeForReserve).div(10000);

            rateTrade = AMP;
            rateFee = takeFee.sub(reserveFee).mul(AMP).div(pair.depth[price]);

            amountOut += getAmountOut(id, pair.depth[price], price);

            amountIn = amountIn.sub(pair.depth[price]).sub(takeFee);
            pair.depth[price] = 0;
        } else {
            takeFee = amountIn.mul(feeForTake).div(10000);
            reserveFee = amountIn.mul(feeForReserve).div(10000);

            rateTrade = amountIn.sub(takeFee).mul(AMP).div(pair.depth[price]);
            rateFee = takeFee.sub(reserveFee).mul(AMP).div(pair.depth[price]);

            amountOut += getAmountOut(id, amountIn.sub(takeFee), price);

            pair.depth[price] = pair.depth[price].sub(amountIn.sub(takeFee));
            amountIn = 0;
        }

        Rate storage rate = pair.tradedRateStored[price][pair.tradedRateStored[price].length - 1];

        rate.fee += calcRate(rateFee, rate.traded);
        rate.traded += calcRate(rateTrade, rate.traded);

        return (amountIn, amountOut, reserveFee);
    }

    

    function getAmountOut(uint256 id, uint256 amountIn, uint256 price) public view returns(uint256) {
        int8 exp = getPair[id].decimals;
        if(exp > 0) {
            return amountIn.mul(10 ** uint(exp)).div(price);
        } else {
            return amountIn.div(10 ** uint(-exp)).div(price);
        }
    }

    function getAmountIn(uint256 id, uint256 amountOut, uint256 price) public view returns(uint256) {
        int8 exp = getPair[id].decimals;
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
        uint id = getPairId[tokenOut][tokenIn];
        
        for(uint256 i = 0; i < getPair[id].prices.length; i++) {
            uint256 p = getPair[id].prices[i];
            if(getPair[id].depth[p] == 0) {
                continue;
            }

            uint256 amountWithFee = getAmountIn(id, amountOut, p).mul(10000 + feeForTake).div(10000);

            if(amountWithFee > getPair[id].depth[p]) {
                amountIn += getPair[id].depth[p].mul(10000 + feeForTake).div(10000);
                amountOut = amountOut.sub(getAmountOut(id, getPair[id].depth[p], p));
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
        uint id = getPairId[tokenOut][tokenIn];

        for(uint256 i = 0; i < getPair[id].prices.length; i++) {
            uint256 p = getPair[id].prices[i];
            if(getPair[id].depth[p] == 0) {
                continue;
            }

            uint256 amountWithFee = getPair[id].depth[p].add(getPair[id].depth[p].mul(feeForTake).div(10000));

            if(amountIn >= amountWithFee) {
                // amountOut += depth[id][p].mul(1e18).div(p);
                amountOut += getAmountOut(id, getPair[id].depth[p], p);
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

    function getLiquidity(
        address account, 
        address tokenIn, 
        address tokenOut, 
        uint256 price
    ) public view returns(uint256 feeRewarded, uint256 filled, uint256 pending) {
        uint256 id = getPairId[tokenIn][tokenOut];

        // Pair storage pair = getPair[id];
        Order memory order = userOrders[account][id][price];

        if(order.pendingOut == 0) {
            return (0, 0, 0);
        }

        Rate[] memory rates = getPair[id].tradedRateStored[price];

        uint256 accumlatedRate = 0;
        uint256 accumlatedRateFee = 0;
        uint256 startIndex = order.rateRedeemedIndex;

        for(uint256 i = startIndex; i < rates.length; i++) {
            accumlatedRateFee += calcRate(rates[i].fee, i == startIndex ? 0 : rates[i - 1].traded);
            accumlatedRate += calcRate(rates[i].traded, i == startIndex ? 0 : rates[i - 1].traded);
            if(rates[i].traded == AMP) {
                break;
            }
        }
        filled = order.pendingOut.mul(accumlatedRate).div(AMP);
        feeRewarded = order.pendingOut.mul(accumlatedRateFee).div(AMP);
        pending = order.pendingOut.sub(filled);
    }

    function getAllLiquidities(
        address account, 
        address tokenIn, 
        address tokenOut
    ) public view returns(uint256[4][] memory, uint256 size) {
        uint256 id = getPairId[tokenIn][tokenOut];
        Pair memory pair = getPair[id];

        uint256[4][] memory liqs = new uint256[4][](pair.prices.length);

        uint256 j = 0;
        for(uint256 i; i < pair.prices.length; i++) {
            (uint256 feeRewarded, uint256 filled, uint256 pending) = getLiquidity(account, tokenIn, tokenOut, pair.prices[i]);
            if(feeRewarded == 0 && filled == 0 && pending == 0) {
                continue;
            }
            liqs[j][0] = pair.prices[i];
            liqs[j][1] = feeRewarded;
            liqs[j][2] = filled;
            liqs[j][3] = pending;
            j++;
        }

        return (liqs, j + 1);
    }
}