// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./StakeDex.sol";

// import "../interfaces/IPancakePair.sol";
import "../interfaces/IPancakeFactory.sol";
import "../interfaces/IWETH.sol";

import "../lib/PancakeLibrary.sol";
import "../lib/TransferHelper.sol";

interface IProofOfTrade {
    function validCOWBHolder(address user) external view returns(bool);
    function record(address user, address token, uint256 amount) external;
}

contract RouterV2 {
    using SafeMath for uint256;

    address public dex; 
    address public factory;
    address public WETH;

    // IProofOfTrade public pot;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'EXPIRED');
        _;
    }

    constructor(address _dex, address _factory, address _WETH/*, address _pot*/) public {
        dex = _dex;
        factory = _factory;
        WETH = _WETH;
        // pot = IProofOfTrade(_pot);
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


    function exactInput(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        bool receiveETH
    ) external payable ensure(deadline) returns (uint[] memory amounts) {
        address[] memory recipients;
        (amounts, recipients) = getAmountsOut(amountIn, path, to);
        require(amounts[path.length - 1] >= amountOutMin, "CowswapRouter: INSUFFICIENT_OUTPUT_AMOUNT");

        if(msg.value == amountIn && path[0] == WETH) {
            IWETH(WETH).deposit{value: amountIn}();
            assert(IWETH(WETH).transfer(recipients[0], amountIn));
        } else {
            IERC20(path[0]).transferFrom(msg.sender, recipients[0], amounts[0]);
        }

        receiveETH = receiveETH && path[path.length - 1] == WETH;
        if(receiveETH) {
            recipients[recipients.length - 1] = address(this);
        }

        for(uint i; i < path.length - 1; i++) {
            if(recipients[i] == dex) {
                StakeDex(dex).swap(path[i], path[i + 1], 0, recipients[i + 1]);
            } else {
                (address input, address output) = (path[i], path[i + 1]);
                (address token0,) = PancakeLibrary.sortTokens(input, output);
                IPancakePair pair = IPancakePair(PancakeLibrary.pairFor(factory, input, output));
                uint amountInput;
                uint amountOutput;
                { // scope to avoid stack too deep errors
                (uint reserve0, uint reserve1,) = pair.getReserves();
                (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
                amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
                amountOutput = PancakeLibrary.getAmountOut(amountInput, reserveInput, reserveOutput);
                }
                (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
                pair.swap(amount0Out, amount1Out, recipients[i + 1], new bytes(0));
            }
        }

        if(receiveETH) {
            uint amountOut = IERC20(WETH).balanceOf(address(this));
            require(amountOut >= amountOutMin, 'CowswapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
            IWETH(WETH).withdraw(amountOut);
            TransferHelper.safeTransferETH(to, amountOut);
        }

        // pot.record(msg.sender, path[path.length - 1], amounts[amounts.length - 1]);
    }

    function exactOutput(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline,
        bool receiveETH
    ) external payable ensure(deadline) returns(uint[] memory amounts) {
        address[] memory recipients;
        (amounts, recipients) = getAmountsIn(amountOut, path, to);
        require(amountInMax >= amounts[0], "CowswapRouter: EXCESSIVE_INPUT_AMOUNT");

        if(msg.value >= amounts[0] && path[0] == WETH) {
            IWETH(WETH).deposit{value: amounts[0]}();
            assert(IWETH(WETH).transfer(recipients[0], amounts[0]));
        } else {
            IERC20(path[0]).transferFrom(msg.sender, recipients[0], amounts[0]);
        }

        receiveETH = receiveETH && path[path.length - 1] == WETH;
        if(receiveETH) {
            recipients[recipients.length - 1] = address(this);
        }

        for(uint i; i < path.length - 1; i++) {
            if(recipients[i] == dex) {
                StakeDex(dex).swap(path[i], path[i + 1], 0, recipients[i + 1]);
            } else {
                (address input, address output) = (path[i], path[i + 1]);
                (address token0,) = PancakeLibrary.sortTokens(input, output);
                IPancakePair pair = IPancakePair(PancakeLibrary.pairFor(factory, input, output));
                uint amountInput;
                uint amountOutput;
                { // scope to avoid stack too deep errors
                (uint reserve0, uint reserve1,) = pair.getReserves();
                (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
                amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
                amountOutput = PancakeLibrary.getAmountOut(amountInput, reserveInput, reserveOutput);
                }
                (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
                pair.swap(amount0Out, amount1Out, recipients[i + 1], new bytes(0));
            }
        }

        if(receiveETH) {
            uint balanceWETH = IERC20(WETH).balanceOf(address(this));
            require(balanceWETH >= amountOut, "CowswapRouter: INSUFFICIENT_OUTPUT_AMOUNT");
            IWETH(WETH).withdraw(amountOut);
            TransferHelper.safeTransferETH(to, amountOut);
        }

        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);


        // pot.record(msg.sender, path[path.length - 1], amounts[amounts.length - 1]);
    }


    function getAmountsOut(
        uint amountIn, 
        address[] memory path, 
        address to
    ) public view returns(uint[] memory amounts, address[] memory recipients) {
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        recipients = new address[](path.length);
        recipients[path.length - 1] = to;

        for(uint i; i < path.length - 1; i++) {
            uint ammOut = amm_calcOutAmount(path[i], path[i + 1], amounts[i]);
            (uint dexOut, uint unfilled) = dex_calcOutAmount(path[i], path[i + 1], amounts[i]);
            if(unfilled > 0) {
                dexOut = dexOut.add(amm_calcOutAmount(path[i], path[i + 1], unfilled));
            }
            if(dexOut > 0 && dexOut > ammOut) {
                amounts[i + 1] = dexOut;
                recipients[i] = dex;
            } else {
                amounts[i + 1] = ammOut;
                recipients[i] = PancakeLibrary.pairFor(factory, path[i], path[i + 1]);
            }
        }
    }

    function getAmountsIn(
        uint amountOut, 
        address[] memory path, 
        address to
    ) public view returns(uint[] memory amounts, address[] memory recipients) {
        amounts = new uint[](path.length);
        amounts[path.length - 1] = amountOut;
        recipients = new address[](path.length);
        recipients[path.length - 1] = to;

        for (uint i = path.length - 1; i > 0; i--) {
            uint ammIn = amm_calcInAmount(path[i - 1], path[i], amounts[i]);
            (uint dexIn, ) = dex_calcInAmount(path[i - 1], path[i], amounts[i]);
            if(dexIn > 0 && ammIn > dexIn) {
                amounts[i - 1] = dexIn;
                recipients[i - 1] = dex;
            } else {
                amounts[i - 1] = ammIn;
                recipients[i - 1] = PancakeLibrary.pairFor(factory, path[i - 1], path[i]);
            }
        }
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