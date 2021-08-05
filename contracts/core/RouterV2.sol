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
    address public ETH = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

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

    function ammSwap(address input, address output, address to) internal returns(uint) {
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
        pair.swap(amount0Out, amount1Out, to, new bytes(0));
        return amountOutput;
    }

    function dexSwap(address tokenIn, address tokenOut, address to) internal {
        (,uint amountReturn) = StakeDex(dex).swap(tokenIn, tokenOut, to, getPair(tokenIn, tokenOut));
        if(amountReturn > 0) {
            ammSwap(tokenIn, tokenOut, to);
        }
    }

    modifier checkExactOutput(address token, address recipient, uint expectOut) { 
        uint balanceBefore = IERC20(token).balanceOf(recipient);
        _; 
        uint actualOut = IERC20(token).balanceOf(recipient).sub(balanceBefore);
        require(expectOut == actualOut, "ExactOutput: IOA");
    }
    
    modifier checkExactInput(address token, address recipient, uint amountOutMin) { 
        uint balanceBefore = IERC20(token).balanceOf(recipient);
        _; 
        uint actualOut = IERC20(token).balanceOf(recipient).sub(balanceBefore);
        require(actualOut >= amountOutMin, "ExactInput: IOA");
    }

    function pay(address token, address payer, address recipient, uint amount) internal {
        if(token == WETH && msg.value == amount) {
            IWETH(WETH).deposit{value: amount}();
            assert(IWETH(WETH).transfer(recipient, amount));
        } else {
            if(payer == address(this)) {
                TransferHelper.safeTransfer(token, recipient, amount);
            } else {
                TransferHelper.safeTransferFrom(token, payer, recipient, amount);
            }
        }
    }

    function getPair(address tokenIn, address tokenOut) internal view returns(address) {
        return PancakeLibrary.pairFor(factory, tokenIn, tokenOut);
    }

    function exactInput(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) 
    external 
    payable 
    ensure(deadline) 
    checkExactInput(path[path.length - 1], to, amountOutMin)
    returns (uint[] memory amounts) 
    {
        address[] memory recipients;
        (amounts,,recipients) = getAmountsOut(amountIn, path, to);
        require(amounts[path.length - 1] >= amountOutMin, "CowswapRouter: IOA"); // INSUFFICIENT_OUTPUT_AMOUNT

        pay(path[0], msg.sender, recipients[0], amounts[0]);

        for(uint i; i < path.length - 1; i++) {
            if(recipients[i] == dex) {
                dexSwap(path[i], path[i + 1], recipients[i + 1]);
            } else {
                ammSwap(path[i], path[i + 1], recipients[i + 1]);
            }
        }
        // pot.record(msg.sender, path[path.length - 1], amounts[amounts.length - 1]);
    }

    function exactOutput(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) 
    external 
    payable 
    ensure(deadline) 
    checkExactOutput(path[path.length - 1], to, amountOut)
    returns(uint[] memory amounts)
    {
        address[] memory recipients;
        (amounts,,recipients) = getAmountsIn(amountOut, path, to);
        require(amountInMax >= amounts[0], "CowswapRouter: EIA"); // EXCESSIVE_INPUT_AMOUNT

        pay(path[0], msg.sender, recipients[0], amounts[0]);

        for(uint i; i < path.length - 1; i++) {
            if(recipients[i] == dex) {
                dexSwap(path[i], path[i + 1], recipients[i + 1]);
            } else {
                ammSwap(path[i], path[i + 1], recipients[i + 1]);
            }
        }
        // pot.record(msg.sender, path[path.length - 1], amounts[amounts.length - 1]);
    }


    function getAmountsOut(
        uint amountIn, 
        address[] memory path, 
        address to
    ) public view returns(
        uint[] memory amounts, 
        uint[] memory unfilledAmounts,
        address[] memory recipients
    ) {
        amounts = new uint[](path.length);
        unfilledAmounts = new uint[](path.length);

        amounts[0] = amountIn;
        recipients = new address[](path.length);
        recipients[path.length - 1] = to;

        for(uint i; i < path.length - 1; i++) {
            uint ammOut = amm_calcOutAmount(path[i], path[i + 1], amounts[i]);
            (uint dexOut, uint unfilledIn) = dex_calcOutAmount(path[i], path[i + 1], amounts[i]);
            if(dexOut > 0 && unfilledIn > 0) {
                dexOut = dexOut.add(amm_calcOutAmount(path[i], path[i + 1], unfilledIn));
                unfilledAmounts[i] = unfilledIn;
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
    ) public view returns(
        uint[] memory amounts, 
        uint[] memory unfilledAmounts,
        address[] memory recipients
    ) {
        amounts = new uint[](path.length);
        amounts[path.length - 1] = amountOut;

        unfilledAmounts = new uint[](path.length);

        recipients = new address[](path.length);
        recipients[path.length - 1] = to;

        for (uint i = path.length - 1; i > 0; i--) {
            uint ammIn = amm_calcInAmount(path[i - 1], path[i], amounts[i]);
            (uint dexIn, uint unfilledOut) = dex_calcInAmount(path[i - 1], path[i], amounts[i]);
            if(dexIn > 0 && unfilledOut > 0) {
                uint partialAmmIn = amm_calcInAmount(path[i - 1], path[i], unfilledOut);
                dexIn = dexIn.add(partialAmmIn);
                unfilledAmounts[i - 1] = partialAmmIn;
            }
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