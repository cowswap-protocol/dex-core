// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "../interfaces/IPancakeFactory.sol";
import "../lib/PancakeLibrary.sol";

import "./Validation.sol";
import "./Payment.sol";


contract Liquidity is Validation, Payment {
    using SafeMath for uint256;

    address public factory;

    constructor(address _factory, address _WETH) public Payment(_WETH) {
        factory = _factory;
    }


    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal virtual returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        if (IPancakeFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            IPancakeFactory(factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = PancakeLibrary.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = PancakeLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'CowswapRouter: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = PancakeLibrary.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'CowswapRouter: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external payable ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(
            wrap(tokenA),
            wrap(tokenB), 
            amountADesired, 
            amountBDesired, 
            amountAMin, 
            amountBMin
        );
        address pair = PancakeLibrary.pairFor(
            factory, 
            wrap(tokenA), 
            wrap(tokenB)
        );
        _deposit(tokenA, msg.sender, pair, amountA);
        _deposit(tokenB, msg.sender, pair, amountB);
        liquidity = IPancakePair(pair).mint(to);
    }

    function _removeLiquidityInternal(
        address tokenA,
        address tokenB,
        uint liquidity,
        address to
    ) internal returns(uint amountA, uint amountB) {
        address pair = PancakeLibrary.pairFor(factory, wrap(tokenA), wrap(tokenB));
        IPancakePair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        address _to = (tokenA == ETH || tokenB == ETH) ? address(this) : to;
        uint amountABefore = IERC20(wrap(tokenA)).balanceOf(_to);
        uint amountBBefore = IERC20(wrap(tokenB)).balanceOf(_to);
        IPancakePair(pair).burn(_to);
        amountA = IERC20(wrap(tokenA)).balanceOf(_to).sub(amountABefore);
        amountB = IERC20(wrap(tokenB)).balanceOf(_to).sub(amountBBefore);
    }


    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public ensure(deadline) returns (uint amountA, uint amountB) {
        (amountA, amountB) = _removeLiquidityInternal(tokenA, tokenB, liquidity, to);
        require(amountA >= amountAMin, 'CowswapRouter: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'CowswapRouter: INSUFFICIENT_B_AMOUNT');

        if(tokenA == ETH || tokenB == ETH) {
            _withdraw(tokenA, to, amountA);
            _withdraw(tokenB, to, amountB);
        }
    }

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB) {
        IPancakePair(PancakeLibrary.pairFor(factory, wrap(tokenA), wrap(tokenB))).permit(msg.sender, address(this), approveMax ? uint(-1) : liquidity, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }
}