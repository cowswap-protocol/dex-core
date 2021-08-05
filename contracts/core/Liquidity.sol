// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./StakeDex.sol";

// import "../interfaces/IPancakePair.sol";
import "../interfaces/IPancakeFactory.sol";
import "../interfaces/IWETH.sol";

import "../lib/PancakeLibrary.sol";
import "../lib/TransferHelper.sol";

contract Liquidity {
    using SafeMath for uint256;
    
    address public factory;
    address public WETH;
    address public ETH = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'EXPIRED');
        _;
    }

    constructor(address _factory, address _WETH/*, address _pot*/) public {
        factory = _factory;
        WETH = _WETH;
    }

    receive() external payable {
        // assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
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
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = PancakeLibrary.pairFor(factory, tokenA, tokenB);

        if(tokenA == WETH) {
            IWETH(WETH).deposit{value: amountA}();
            assert(IWETH(WETH).transfer(pair, amountA));
            if(msg.value > amountA) {
                TransferHelper.safeTransferETH(msg.sender, msg.value - amountA);
            }
            TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        } else if(tokenB == WETH) {
            IWETH(WETH).deposit{value: amountB}();
            assert(IWETH(WETH).transfer(pair, amountB));
            if(msg.value > amountB) {
                TransferHelper.safeTransferETH(msg.sender, msg.value - amountB);
            }
            TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        } else {
            TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
            TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        }

        liquidity = IPancakePair(pair).mint(to);
    }


    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool receiveETH
    ) public ensure(deadline) returns (uint amountA, uint amountB) {
        receiveETH = receiveETH && (tokenA == WETH || tokenB == WETH);
        address pair = PancakeLibrary.pairFor(factory, tokenA, tokenB);
        IPancakePair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = IPancakePair(pair).burn(receiveETH ? address(this) : to);
        (address token0,) = PancakeLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'CowswapRouter: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'CowswapRouter: INSUFFICIENT_B_AMOUNT');
        if(receiveETH) {
            if(tokenA == WETH) {
                IWETH(WETH).withdraw(amountA);
                TransferHelper.safeTransferETH(to, amountA);
                TransferHelper.safeTransfer(tokenB, to, amountB);
            } else if(tokenB == WETH) {
                IWETH(WETH).withdraw(amountB);
                TransferHelper.safeTransferETH(to, amountB);
                TransferHelper.safeTransfer(tokenA, to, amountA);
            }
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
        bool receiveETH,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB) {
        IPancakePair(PancakeLibrary.pairFor(factory, tokenA, tokenB)).permit(msg.sender, address(this), approveMax ? uint(-1) : liquidity, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline, receiveETH);
    }

    function dex_calcOutAmount(address tokenIn, address tokenOut, uint amountIn) public view returns(uint, uint) {
        return StakeDex(dex).calcOutAmount(tokenIn, tokenOut, amountIn);
    }

    function dex_calcInAmount(address tokenIn, address tokenOut, uint amountOut) public view returns(uint, uint) {
        return StakeDex(dex).calcInAmount(tokenIn, tokenOut, amountOut);
    }

    function amm_calcOutAmount(address tokenIn, address tokenOut, uint amountIn) public view returns(uint) {
        return PancakeLibrary.calcOutAmount(factory, tokenIn, tokenOut, amountIn);
    }

    function amm_calcInAmount(address tokenIn, address tokenOut, uint amountOut) public view returns(uint) {
        return PancakeLibrary.calcInAmount(factory, tokenIn, tokenOut, amountOut);
    }
}