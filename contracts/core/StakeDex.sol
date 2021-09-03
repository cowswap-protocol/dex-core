// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./IERC20.sol";
import "./Payment.sol";

contract StakeDex is ERC721('Cowswap Position', 'COW-POS'), Payment {
    using SafeMath for uint256;

    uint8 constant ETHER_IN = 1;
    uint8 constant ETHER_OUT = 2;

    uint public AMP = 1e22;

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
    
    int8 public defaultDecimals = 16;

    address public feeTo;
    address public gov;

    uint public feeForTake = 20; // 0.2% 
    uint public feeForProvide = 10; // 0.10% to makers
    uint public feeForReserve = 10; // 0.10% reserved

    mapping (address => uint256) public reserves;

    struct Position {
        uint256 pairId;
        uint256 price;
        uint256 pendingOut;
        uint256 rateRedeemedIndex;
        uint8 etherInOrOut;
    }

    uint256 private _nextId = 1;
    uint256 public nextPairId = 0;

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
    

    constructor(address feeTo_, address _WETH) public Payment(_WETH) {
        gov = msg.sender;
        feeTo = feeTo_;
    }

    function setGov(address _newGov) external onlyGov {
        gov = _newGov;
    }

    function setBaseURI(string memory _baseURI) external onlyGov {
        _setBaseURI(_baseURI);
    }

    function setFees(uint256 take_, uint256 provide_, uint256 reserve_) public onlyGov {
        require(take_ == provide_.add(reserve_), "take_ != provide_ + reserve_");
        feeForTake = take_;
        feeForProvide = provide_;
        feeForReserve = reserve_;
    }

    function createPair(address tokenIn, address tokenOut) public {
        tokenIn = wrap(tokenIn);
        tokenOut = wrap(tokenOut);
        require(IERC20(tokenIn).decimals() <= 18, "TokenIn decimals > 18");
        require(IERC20(tokenOut).decimals() <= 18, "TokenOut decimals > 18");

        if(getPairId[tokenIn][tokenOut] > 0) {
            return;
        }

        nextPairId++;
        getPairId[tokenIn][tokenOut] = nextPairId;
        
        uint256 id = getPairId[tokenIn][tokenOut];

        int8 decimals = int8(defaultDecimals) + int8(IERC20(tokenIn).decimals()) - int8(IERC20(tokenOut).decimals());

        Pair storage pair = getPair[id];
        pair.id = id;
        pair.decimals = decimals;
        pair.tokenIn = tokenIn;
        pair.tokenOut = tokenOut;

        emit CreatePair(tokenIn, tokenOut, id);
    }

    function increasePairDecimals(address tokenIn, address tokenOut, int8 pairDecimals) external onlyGov {
        int8 decimals = int8(pairDecimals) + int8(IERC20(tokenIn).decimals()) - int8(IERC20(tokenOut).decimals());
        int8 old = getPair[getPairId[tokenIn][tokenOut]].decimals;

        require(decimals > old, "Can not increase deciamls");

        Pair storage pair = getPair[getPairId[tokenIn][tokenOut]];
        pair.decimals = decimals;
        for(uint256 i = 0; i < pair.prices.length; i++) {
            pair.prices[i] = pair.prices[i].mul(10 ** uint(decimals - old));
        }
    }

    function decreasePairDecimals(address tokenIn, address tokenOut, int8 pairDecimals) external onlyGov {
        int8 decimals = int8(pairDecimals) + int8(IERC20(tokenIn).decimals()) - int8(IERC20(tokenOut).decimals());
        int8 old = getPair[getPairId[tokenIn][tokenOut]].decimals;
        require(decimals < old, "Can not decrease deciamls");
        Pair storage pair = getPair[getPairId[tokenIn][tokenOut]];
        require(pair.prices.length == 0, "Prices is not empty");
        pair.decimals = decimals;
    }


    function updateDefaultDecimals(int8 decimals_) external onlyGov {
        defaultDecimals = decimals_;
    }

    function _updateReserve(address token) internal {
        reserves[token] = IERC20(token).balanceOf(address(this));
    }

    function _deposit(address token, address from, uint256 amount) internal returns(uint256) {
        uint256 balanceBefore = IERC20(wrap(token)).balanceOf(address(this));
        _deposit(token, from, address(this), amount);
        return IERC20(wrap(token)).balanceOf(address(this)).sub(balanceBefore);
    }

    function _recordRateIndex(uint256 id, uint256 price) internal returns(uint256 rateIndex) {
        Pair storage pair = getPair[id];
        uint256 size = pair.tradedRateStored[price].length;
        if(pair.tradedRateStored[price][size - 1].traded == 0) {
            rateIndex = size - 1;
        } else {
            pair.tradedRateStored[price].push(ZERO);
            rateIndex = size;
        }
    }

    
    function mint(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    ) external payable lock returns(uint256 tokenId)
    {   
        bool isEtherIn = isETH(tokenIn);
        bool isEtherOut = isETH(tokenOut);
        tokenIn = wrap(tokenIn);
        tokenOut = wrap(tokenOut);

        require(amountIn > 0 && amountOut > 0, "ZERO");

        if(getPairId[tokenIn][tokenOut] == 0) {
            createPair(tokenIn, tokenOut);
        }
        uint256 id = getPairId[tokenIn][tokenOut];
        Pair storage pair = getPair[id];

        amountIn = _deposit(isEtherIn ? ETH : tokenIn, msg.sender, amountIn);

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
        position.etherInOrOut = isEtherIn ? uint8(1) : (isEtherOut ? uint8(2) : uint8(0));

        emit IncreasePosition(msg.sender, tokenIn, tokenOut, price, amountIn);
    }

    function increasePosition(uint256 tokenId, uint256 amountIn) external payable lock {
        _redeemTraded(tokenId);
        Position storage position = _positions[tokenId];
        Pair storage pair = getPair[position.pairId];
        amountIn = _deposit(position.etherInOrOut == ETHER_IN ? ETH : pair.tokenIn, msg.sender, amountIn);
        uint256 amountOut = getAmountIn(position.pairId, amountIn, position.price);
        pair.depth[position.price] = pair.depth[position.price].add(amountOut);

        position.pendingOut = position.pendingOut.add(amountOut);
        position.rateRedeemedIndex = _recordRateIndex(position.pairId, position.price);
        _updateReserve(pair.tokenIn);

        emit IncreasePosition(msg.sender, pair.tokenIn, pair.tokenOut, position.price, amountIn);
    }


    function decreasePosition(uint256 tokenId, uint256 amountIn) external lock isAuthorizedForToken(tokenId) {
        require(amountIn > 0, "ZERO");
        _redeemTraded(tokenId);
        Position storage position = _positions[tokenId];
        Pair storage pair = getPair[position.pairId];
        uint256 amountOut = getAmountIn(position.pairId, amountIn, position.price);
        require(position.pendingOut >= amountOut, "Insufficient position");

        pair.depth[position.price] = pair.depth[position.price].sub(amountOut);
        position.pendingOut = position.pendingOut.sub(amountOut);
        position.rateRedeemedIndex = _recordRateIndex(position.pairId, position.price);
        
        // recalculate amountIn to prevent withdrawing with insufficient input amount
        uint calcAmountIn = getAmountOut(position.pairId, amountOut, position.price);
        _withdraw(position.etherInOrOut == ETHER_IN ? ETH : pair.tokenIn, ownerOf(tokenId), calcAmountIn);

        _updateReserve(pair.tokenIn);

        emit DecreasePosition(msg.sender, pair.tokenIn, pair.tokenOut, position.price, amountIn);
    }

    function burn(uint256 tokenId) external lock isAuthorizedForToken(tokenId) {
        address owner = ownerOf(tokenId);
        Position storage position = _positions[tokenId];
        Pair storage pair = getPair[position.pairId];
        _redeemTraded(tokenId);
        
        uint amountIn;

        if(pair.depth[position.price] >= position.pendingOut) {
            amountIn = getAmountOut(position.pairId, position.pendingOut, position.price);
            pair.depth[position.price] = pair.depth[position.price].sub(position.pendingOut);
        } else {
            amountIn = getAmountOut(position.pairId, pair.depth[position.price], position.price);
            pair.depth[position.price] = 0;
        }

        if(amountIn > 0) {
            _withdraw(position.etherInOrOut == ETHER_IN ? ETH : pair.tokenIn, owner, amountIn);
        }
        
        // burn
        _burn(tokenId);

        _updateReserve(pair.tokenIn);
        
        emit DecreasePosition(msg.sender, pair.tokenIn, pair.tokenOut, position.price, amountIn);
        
        delete _positions[tokenId];
    }

    function _redeemTraded(uint256 tokenId) internal {
        Position storage position = _positions[tokenId];
        Pair storage pair = getPair[position.pairId];
        if(position.pendingOut == 0){
            return;
        }

        address owner = ownerOf(tokenId);

        Rate[] storage rates = pair.tradedRateStored[position.price];

        uint256 accumlatedRate = 0;
        uint256 accumlatedRateFee = 0;

        for(uint256 i = position.rateRedeemedIndex; i < rates.length; i++) {
            accumlatedRateFee = calcRate(rates[i].fee, accumlatedRate).add(accumlatedRateFee);
            accumlatedRate = calcRate(rates[i].traded, accumlatedRate).add(accumlatedRate);

            if(rates[i].traded == AMP) {
                break;
            }
        }

        uint256 filled = position.pendingOut.mul(accumlatedRate).div(AMP);
        uint256 fee = position.pendingOut.mul(accumlatedRateFee).div(AMP);

        if(filled > 0) {
            position.pendingOut = position.pendingOut.sub(filled);
            _withdraw(position.etherInOrOut == ETHER_OUT ? ETH : pair.tokenOut, owner, filled.add(fee));

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
        address to,
        address refundTo
    ) external lock returns(uint256 amountOut, uint256 amountReturn)
    {   
        uint id = getPairId[tokenOut][tokenIn];

        Pair storage pair = getPair[id];

        uint256 amountIn = IERC20(tokenIn).balanceOf(address(this)).sub(reserves[tokenIn]);

        uint total = amountIn;
        uint totalFee = 0;
        uint totalProvideFee = 0;

        for(uint256 i = 0; i < pair.prices.length; i++) {
            uint256 p = pair.prices[i];

            if(pair.depth[p] == 0) {
                continue;
            }
            (uint _amountReturn, uint _amountOut, uint _reserveFee, uint _provideFee) = _swapWithFixedPrice(id, amountIn, p);

            totalFee = totalFee.add(_reserveFee);
            totalProvideFee = totalProvideFee.add(_provideFee);
            amountOut = amountOut.add(_amountOut);
            amountIn = _amountReturn;

            if(amountIn == 0) {
                break;
            }
        }

        amountReturn = amountIn;

        // fee
        IERC20(tokenIn).transfer(feeTo, totalFee);

        // swap out
        if(to != address(this)) {
            IERC20(tokenOut).transfer(to, amountOut);
        }

        // refund
        if(amountReturn > 0 && refundTo != address(this)) {
            IERC20(tokenIn).transfer(refundTo == address(0) ? msg.sender : refundTo, amountReturn);
        }

        reserves[tokenIn] = reserves[tokenIn].add(total.sub(amountReturn).sub(totalProvideFee));
        reserves[tokenOut] = reserves[tokenOut].sub(amountOut);

        emit Swap(msg.sender, tokenIn, tokenOut, total.sub(amountReturn), amountOut);
    }


    function _swapWithFixedPrice(
        uint id,
        uint amountIn, 
        uint price
    ) internal returns(uint /*amountReturn*/, uint amountOut, uint reserveFee, uint provideFee) {
        Pair storage pair = getPair[id];
        
        uint256 rateTrade;
        uint256 rateFee;
        uint256 amount;
        uint256 amountInMaxWithFee = pair.depth[price].mul(10000).div(10000 - feeForTake);

        if(amountIn >= amountInMaxWithFee) {
            amount = amountInMaxWithFee;
            amountIn = amountIn.sub(amountInMaxWithFee);
        } else {
            amount = amountIn;
            amountIn = 0;
        }

        uint takeFee = amount.mul(feeForTake).div(10000);
        provideFee = amount.mul(feeForProvide).div(10000);
        reserveFee = takeFee.sub(provideFee);

        rateTrade = amount.sub(takeFee).mul(AMP).div(pair.depth[price]);
        rateFee = provideFee.mul(AMP).div(pair.depth[price]);

        amountOut = getAmountOut(id, amount.sub(takeFee), price);

        if(amountIn >= amountInMaxWithFee) {
            pair.depth[price] = 0; 
        } else {
            pair.depth[price] = pair.depth[price].sub(amount.sub(takeFee));
        }

        Rate storage rate = pair.tradedRateStored[price][pair.tradedRateStored[price].length - 1];

        rate.fee = rate.fee.add(calcRate(rateFee, rate.traded));
        rate.traded = rate.traded.add(calcRate(rateTrade, rate.traded));

        return (amountIn, amountOut, reserveFee, provideFee);
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
            uint256 amountOutMax = getAmountOut(id, getPair[id].depth[p], p);

            if(amountOut > amountOutMax) {
                amountIn = getPair[id].depth[p].mul(10000).div(10000 - feeForTake).add(amountIn);
                amountOut = amountOut.sub(amountOutMax);
            } else {
                uint inputAmount = getAmountIn(id, amountOut, p);
                amountIn = inputAmount.mul(10000).div(10000 - feeForTake).add(amountIn);
                amountOut = 0;
                break;
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

            uint256 amountWithFee = getPair[id].depth[p].mul(10000).div(10000 - feeForTake);

            if(amountIn >= amountWithFee) {
                amountOut = getAmountOut(id, getPair[id].depth[p], p).add(amountOut);
                amountIn = amountIn.sub(amountWithFee);
            } else {
                uint256 fee = amountIn.mul(feeForTake).div(10000);
                amountOut = getAmountOut(id, amountIn.sub(fee), p).add(amountOut);
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
            uint256 pairId,
            uint256 pendingIn,
            uint256 price,
            uint256 pendingOut,
            uint256 rateRedeemedIndex,
            address tokenIn,
            address tokenOut,
            uint256 filled,
            uint256 feeRewarded,
            uint8 etherInOrOut,
            int8 decimals

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

            for(uint256 i = position.rateRedeemedIndex; i < rates.length; i++) {
                accumlatedRateFee = calcRate(rates[i].fee, accumlatedRate).add(accumlatedRateFee);
                accumlatedRate = calcRate(rates[i].traded, accumlatedRate).add(accumlatedRate);

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
            position.pairId,
            pendingIn,
            position.price,
            pendingOut,
            position.rateRedeemedIndex,
            pair.tokenIn,
            pair.tokenOut,
            filled,
            feeRewarded,
            position.etherInOrOut,
            pair.decimals
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

    function getRates(address tokenIn, address tokenOut, uint price) 
    public
    view
    returns(
        uint[] memory tradedRates,
        uint[] memory feeRates
    ) {
        uint id = getPairId[tokenIn][tokenOut];
        Pair storage pair = getPair[id];
        Rate[] storage rates = pair.tradedRateStored[price];

        tradedRates = new uint[](rates.length);
        feeRates  = new uint[](rates.length);

        for(uint i = 0; i < rates.length; i++) {
            tradedRates[i] = rates[i].traded;
            feeRates[i] = rates[i].fee;
        }
    }
}