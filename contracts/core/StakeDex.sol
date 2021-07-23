// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;


import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./IERC20.sol";


contract StakeDex is ERC721 {
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

        address tokenIn;
        address tokenOut;
    }

    mapping (uint256 => Pair) public getPair;
    mapping (address => mapping (address => uint)) public getPairId;
    
    int8 public defaultDecimals = 10;

    address public feeTo;
    address public gov;

    uint public feeForTake = 20; // 0.2% 
    uint public feeForProvide = 10; // 0.10% to makers
    uint public feeForReserve = 10; // 0.10% reserved

    mapping (address => uint256) public reserves;

    struct Position {
        // the nonce for permits
        uint96 nonce;
        // the address that is approved for spending this token
        address operator;
        uint256 pairId;

        // uint256 amountIn;
        uint256 price;
        uint256 pendingOut;
        uint256 rateRedeemedIndex;
    }

    uint256 private _nextId = 1;

    mapping (uint256 => Position) private _positions;
    
    

    event IncreasePosition(address indexed sender, address tokenIn, address tokenOut, uint price, uint amountIn);
    event DecreasePosition(address indexed sender, address tokenIn, address tokenOut, uint price, uint amountIn);

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

    modifier isAuthorizedForToken(uint256 tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), 'Not approved');
        _;
    }
    

    constructor(address feeTo_) public ERC721('Cowswap Positions', 'COW-POS') {
        gov = msg.sender;
        feeTo = feeTo_;
    }

    function setFees(uint256 take_, uint256 provide_, uint256 reserve_) public onlyGov {
        require(take_ == provide_.add(reserve_), "take_ != provide_ + reserve_");
        feeForTake = take_;
        feeForProvide = provide_;
        feeForReserve = reserve_;
    }

    function createPair(address tokenIn, address tokenOut) public {
        getPairId[tokenIn][tokenOut] += 1;

        uint256 id = getPairId[tokenIn][tokenOut];

        int8 decimals = int8(defaultDecimals) + int8(IERC20(tokenIn).decimals()) - int8(IERC20(tokenOut).decimals());

        Pair storage pair = getPair[id];
        pair.id = id;
        pair.decimals = decimals;
        pair.tokenIn = tokenIn;
        pair.tokenOut = tokenOut;

        emit CreatePair(tokenIn, tokenOut, id);
    }

    function updatePairDecimals(address tokenIn, address tokenOut, int8 decimals_) public {
        require(gov == msg.sender, "Not gov");
        getPair[getPairId[tokenIn][tokenOut]].decimals = int8(decimals_) + int8(IERC20(tokenIn).decimals()) - int8(IERC20(tokenOut).decimals());
    }

    function _updateReserve(address token) internal {
        reserves[token] = IERC20(token).balanceOf(address(this));
    }

    function _deposit(address token, address from, uint256 amount) internal returns(uint256) {
        uint256 beforeBalance = IERC20(token).balanceOf(address(this));
        IERC20(token).transferFrom(from, address(this), amount);
        uint256 afterBalance = IERC20(token).balanceOf(address(this));
        return afterBalance.sub(beforeBalance);
    }

    function _withdraw(address token, address to, uint256 amount) internal {
        require(IERC20(token).balanceOf(address(this)) >= amount, "Insufficient balance");
        IERC20(token).transfer(to, amount);
    }

    function _recordRateIndex(uint256 id, uint256 price) internal returns(uint256 rateIndex) {
        Pair storage pair = getPair[id];
        uint256 size = pair.tradedRateStored[price].length;
        if(pair.tradedRateStored[price][size - 1].traded == 0) {
            // position.rateRedeemedIndex = size - 1;
            rateIndex = size - 1;
        } else {
            pair.tradedRateStored[price].push(ZERO);
            // position.rateRedeemedIndex = size;
            rateIndex = size;
        }
    }

    
    function mint(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    ) external lock returns(uint256 tokenId)
    {   
        require(amountIn > 0 && amountOut > 0, "ZERO");

        if(getPairId[tokenIn][tokenOut] == 0) {
            createPair(tokenIn, tokenOut);
        }
        uint256 id = getPairId[tokenIn][tokenOut];
        Pair storage pair = getPair[id];

        amountIn = _deposit(tokenIn, msg.sender, amountIn);

        uint256 price;

        if(pair.decimals > 0) {
            price = amountOut.mul(10 ** uint(pair.decimals)).div(amountIn);
            amountOut = price.mul(amountIn).div(10 ** uint(pair.decimals));
        } else {
            price = amountOut.div(10 ** uint(-pair.decimals)).div(amountIn);
            amountOut = price.mul(amountIn).mul(10 ** uint(-pair.decimals));
        }

        require(price > 0, "Zero Price");

        pair.depth[price] = pair.depth[price].add(amountOut); 

        addToPriceArray(tokenIn, tokenOut, price);

        if(pair.tradedRateStored[price].length == 0) {
            pair.tradedRateStored[price].push(HEAD);
        }

        _updateReserve(tokenIn);

        _mint(msg.sender, (tokenId = _nextId++));

        Position storage position = _positions[tokenId];
        position.pairId = id;
        position.price = price;
        position.pendingOut = amountOut;
        position.rateRedeemedIndex = _recordRateIndex(position.pairId, position.price);

        emit IncreasePosition(msg.sender, tokenIn, tokenOut, price, amountIn);
    }

    function increasePosition(uint256 tokenId, uint256 amountIn) external lock {
        _redeemTraded(tokenId);
        Position storage position = _positions[tokenId];
        Pair storage pair = getPair[position.pairId];
        amountIn = _deposit(pair.tokenIn, msg.sender, amountIn);
        uint256 amountOut = getAmountIn(position.pairId, amountIn, position.price);
        pair.depth[position.price] = pair.depth[position.price].add(amountOut);

        position.pendingOut = position.pendingOut.add(amountOut);
        position.rateRedeemedIndex = _recordRateIndex(position.pairId, position.price);
        _updateReserve(pair.tokenIn);

        emit IncreasePosition(msg.sender, pair.tokenIn, pair.tokenOut, position.price, amountIn);
    }


    function decreasePosition(uint256 tokenId, uint256 amountIn) external lock isAuthorizedForToken(tokenId) {
        _redeemTraded(tokenId);
        Position storage position = _positions[tokenId];
        Pair storage pair = getPair[position.pairId];
        uint256 amountOut = getAmountIn(position.pairId, amountIn, position.price);
        require(position.pendingOut >= amountOut, "Insufficient position");
        pair.depth[position.price] = pair.depth[position.price].sub(amountOut);

        position.pendingOut = position.pendingOut.sub(amountOut);
        position.rateRedeemedIndex = _recordRateIndex(position.pairId, position.price);
        _withdraw(pair.tokenIn, ownerOf(tokenId), amountIn);
        _updateReserve(pair.tokenIn);

        emit DecreasePosition(msg.sender, pair.tokenIn, pair.tokenOut, position.price, amountIn);
    }

    function burn(uint256 tokenId) external lock isAuthorizedForToken(tokenId) {
        address owner = ownerOf(tokenId);
        Position storage position = _positions[tokenId];
        Pair storage pair = getPair[position.pairId];
        _redeemTraded(tokenId);
        uint amountIn = getAmountOut(position.pairId, position.pendingOut, position.price);
        if(amountIn > 0) {
            _withdraw(pair.tokenIn, owner, amountIn);
        }
        // redeem
        _burn(tokenId);
        delete _positions[tokenId];

        emit DecreasePosition(msg.sender, pair.tokenIn, pair.tokenOut, position.price, amountIn);
    }

    function _redeemTraded(uint256 tokenId) internal {
        Position storage position = _positions[tokenId];
        Pair storage pair = getPair[position.pairId];

        address owner = ownerOf(tokenId);

        require(position.pendingOut > 0, "No Liquidity");

        Rate[] storage rates = pair.tradedRateStored[position.price];

        uint256 accumlatedRate = 0;
        uint256 accumlatedRateFee = 0;
        uint256 startIndex = position.rateRedeemedIndex;


        for(uint256 i = startIndex; i < rates.length; i++) {
            accumlatedRateFee += calcRate(rates[i].fee, i == startIndex ? 0 : rates[i - 1].traded);
            accumlatedRate += calcRate(rates[i].traded, i == startIndex ? 0 : rates[i - 1].traded);
            if(rates[i].traded == AMP) {
                break;
            }
        }
        uint256 filled = position.pendingOut.mul(accumlatedRate).div(AMP);
        uint256 fee = position.pendingOut.mul(accumlatedRateFee).div(AMP);
        if(filled > 0) {
            _withdraw(pair.tokenOut, owner, filled.add(fee));
            position.pendingOut = position.pendingOut.sub(filled);

            _updateReserve(pair.tokenOut);

            emit Redeem(owner, pair.tokenIn, pair.tokenOut, position.price, filled);
        }
    }

    function redeem(uint256 tokenId) external lock isAuthorizedForToken(tokenId) {
        Position storage position = _positions[tokenId];
        _redeemTraded(tokenId);
        position.rateRedeemedIndex = _recordRateIndex(position.pairId, position.price);
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

    // function skimPriceArray(
    //     address tokenIn, 
    //     address tokenOut
    // ) internal 
    // {
    //     uint id = getPairId[tokenIn][tokenOut];
    //     Pair storage pair = getPair[id];
    //     uint256[] storage priceArray = pair.prices;

    //     if(priceArray.length == 0) {
    //         return;
    //     }

    //     if(priceArray.length == 1) {
    //         if(pair.depth[priceArray[0]] == 0) {
    //             priceArray.pop();
    //         }
    //         return;
    //     }

    //     uint256 i = 0;
    //     uint256 len = priceArray.length;

    //     while(i < len) {
    //         uint256 price = priceArray[i];
    //         if(pair.depth[price] == 0) {
    //             for(uint256 j = i; j < len - 1; j++) {
    //                 priceArray[j] = priceArray[j + 1];
    //             }
    //             priceArray.pop();
    //             len = len - 1;
    //         }
    //         i++;
    //     }
    // }

    function calcRate(uint256 currentRate, uint256 storedRate) public view returns(uint256) {
        return uint(AMP).sub(storedRate).mul(currentRate).div(AMP);
    }

    function swap(
        address tokenIn, 
        address tokenOut, 
        uint amountOutMin,
        address to
    ) external returns(uint256 amountOut)
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
            IERC20(tokenIn).transfer(msg.sender, amountIn); // refund
        }

        // IERC20(tokenIn).transferFrom(msg.sender, address(this), total.sub(amountIn));
        IERC20(tokenIn).transfer(feeTo, totalFee);
        // IERC20(tokenOut).transfer(msg.sender, amountOut);
        if(to != address(this)) {
            IERC20(tokenOut).transfer(to, amountOut);
        }

        reserves[tokenOut] = reserves[tokenOut].sub(amountOut);
        _updateReserve(tokenIn);

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
                amountIn += getPair[id].depth[p].add(getPair[id].depth[p].mul(feeForTake).div(10000));
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
                amountOut += getAmountOut(id, getPair[id].depth[p], p);
                amountIn = amountIn.sub(amountWithFee);
            } else {
                uint256 fee = amountIn.mul(feeForTake).div(10000);
                amountOut += getAmountOut(id, amountIn.sub(fee), p);
                amountIn = 0;
                break;
            }
        }

        amountReturn = amountIn;
    }

    function positions(uint256 tokenId) 
        external 
        view 
        returns(
            uint256 nonce,
            address operator,
            uint256 pairId,
            uint256 pendingIn,
            uint256 price,
            uint256 pendingOut,
            uint256 rateRedeemedIndex,
            address tokenIn,
            address tokenOut,
            uint256 filled,
            uint256 feeRewarded
        ) 
    {
        require(_exists(tokenId), "No position");
        Position memory position = _positions[tokenId];
        Pair storage pair = getPair[position.pairId];

        if(position.pendingOut == 0) {
            filled = 0;
            feeRewarded = 0;
            pendingOut = 0;
        } else {
            Rate[] storage rates = pair.tradedRateStored[position.price];

            uint256 accumlatedRate = 0;
            uint256 accumlatedRateFee = 0;
            uint256 startIndex = position.rateRedeemedIndex;
            for(uint256 i = startIndex; i < rates.length; i++) {
                accumlatedRateFee += calcRate(rates[i].fee, i == startIndex ? 0 : rates[i - 1].traded);
                accumlatedRate += calcRate(rates[i].traded, i == startIndex ? 0 : rates[i - 1].traded);
                if(rates[i].traded == AMP) {
                    break;
                }
            }
            filled = position.pendingOut.mul(accumlatedRate).div(AMP);
            feeRewarded = position.pendingOut.mul(accumlatedRateFee).div(AMP);
            pendingOut = position.pendingOut.sub(filled);
        }

        pendingIn = getAmountOut(position.pairId, pendingOut, position.price);

        return (
            position.nonce,
            position.operator,
            position.pairId,
            pendingIn,
            position.price,
            pendingOut,
            position.rateRedeemedIndex,
            pair.tokenIn,
            pair.tokenOut,
            filled,
            feeRewarded
        );
    }


    function pairs(address tokenIn, address tokenOut) 
    public 
    view 
    returns(
        uint256 id,
        int8 decimals,
        uint256[] memory prices,
        uint256[] memory depths
    ) {
        id = getPairId[tokenIn][tokenOut];
        Pair storage pair = getPair[id];
        decimals = pair.decimals;
        prices = pair.prices;
        depths = new uint256[](prices.length);
        for(uint256 i = 0; i < prices.length; i++) {
            depths[i] = pair.depth[prices[i]];
        }
    }
}