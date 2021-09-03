// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./Liquidity.sol";
import "./IStakeDex.sol";
import "../interfaces/IPancakeFactory.sol";

interface IProofOfTrade {
    function validCOWBHolder(address user) external view returns(bool);
    function record(address user, address token, uint256 amount) external;
}

contract CowswapRouter is Liquidity {
    using SafeMath for uint256;

    address public dex; 
    IProofOfTrade public pot;

    modifier onlyCOWBHolder() { 
        require(pot.validCOWBHolder(msg.sender), "Not COWB Holder"); 
        _; 
    }
    

    constructor(address _dex, address _factory, address _WETH, address _pot) public Liquidity(_factory, _WETH) {
        dex = _dex;
        pot = IProofOfTrade(_pot);
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
        (,uint amountReturn) = IStakeDex(dex).swap(tokenIn, tokenOut, to, getPair(tokenIn, tokenOut));
        if(amountReturn > 0) {
            ammSwap(tokenIn, tokenOut, to);
        }
    }

    function getPair(address tokenIn, address tokenOut) internal view returns(address) {
        return IPancakeFactory(factory).getPair(tokenIn, tokenOut);
    }

    function exactInputInternal(
        uint amountIn,
        uint amountOutMin,
        address[] memory path,
        address payer,
        address to
    ) internal returns(uint amountOut) {
        bool isEtherIn = isETH(path[0]);
        bool isEtherOut = isETH(path[path.length - 1]);
        if(isEtherIn) {
            path[0] = WETH;
        }
        if(isEtherOut) {
            path[path.length - 1] = WETH;
        }

        address[] memory recipients;
        uint[] memory amounts;
        (amounts,,recipients) = getAmountsOut(amountIn, path, to);
        require(amounts[path.length - 1] >= amountOutMin, "CowswapRouter: IOA"); // INSUFFICIENT_OUTPUT_AMOUNT
        
        if(isEtherOut) {
            recipients[path.length - 1] = address(this);
        }

        _deposit(isEtherIn ? ETH : path[0], payer, recipients[0], amounts[0]);

        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(recipients[recipients.length - 1]);

        for(uint i; i < path.length - 1; i++) {
            if(recipients[i] == dex) {
                dexSwap(path[i], path[i + 1], recipients[i + 1]);
            } else {
                ammSwap(path[i], path[i + 1], recipients[i + 1]);
            }
        }
        amountOut = IERC20(path[path.length - 1]).balanceOf(recipients[recipients.length - 1]).sub(balanceBefore);

        if(isEtherOut) {
            _withdraw(ETH, to, amountOut);
        }

        pot.record(msg.sender, path[path.length - 1], amountOut.mul(path.length - 1));
    }

    function exactOutputInternal(
        uint amountOut,
        uint amountInMax,
        address[] memory path,
        address payer,
        address to
    ) internal returns(uint amountIn, uint actualAmountOut) {
        bool isEtherIn = isETH(path[0]);
        bool isEtherOut = isETH(path[path.length - 1]);
        if(isEtherIn) {
            path[0] = WETH;
        }
        if(isEtherOut) {
            path[path.length - 1] = WETH;
        }
        address[] memory recipients;
        uint[] memory amounts;
        (amounts,,recipients) = getAmountsIn(amountOut, path, to);
        require(amountInMax >= amounts[0], "CowswapRouter: EIA"); // EXCESSIVE_INPUT_AMOUNT

        if(isEtherOut) {
            recipients[path.length - 1] = address(this);
        }

        _deposit(isEtherIn ? ETH : path[0], payer, recipients[0], amounts[0]);

        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(recipients[recipients.length - 1]);

        for(uint i; i < path.length - 1; i++) {
            if(recipients[i] == dex) {
                dexSwap(path[i], path[i + 1], recipients[i + 1]);
            } else {
                ammSwap(path[i], path[i + 1], recipients[i + 1]);
            }
        }
        
        actualAmountOut = IERC20(path[path.length - 1]).balanceOf(recipients[recipients.length - 1]).sub(balanceBefore);
        amountIn = amounts[0];

        if(isEtherOut) {
            _withdraw(ETH, to, actualAmountOut);
        }

        pot.record(msg.sender, path[path.length - 1], actualAmountOut.mul(path.length - 1));
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
    returns (uint amountOut)
    {   
       amountOut = exactInputInternal(amountIn, amountOutMin, path, msg.sender, to);
       require(amountOut >= amountOutMin, "ExactInput: IOA");
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
    returns(uint amountIn)
    {
        uint actualAmountOut;
        (amountIn, actualAmountOut) = exactOutputInternal(amountOut, amountInMax, path, msg.sender, to);
        require(actualAmountOut >= amountOut, "ExactOutput: IOA");
        if(isETH(path[0]) && msg.value > amountIn) {
            TransferHelper.safeTransferETH(msg.sender, msg.value - amountIn);
        }
    }

    function exactOutputSupportingFeeOnTransferTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) 
    external 
    payable 
    ensure(deadline) 
    returns(uint amountIn)
    {
        (amountIn,) = exactOutputInternal(amountOut, amountInMax, path, msg.sender, to);
        if(isETH(path[0]) && msg.value > amountIn) {
            TransferHelper.safeTransferETH(msg.sender, msg.value - amountIn);
        }
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
            if(unfilledIn > 0) {
                uint ammUnfilledOut = amm_calcOutAmount(path[i], path[i + 1], unfilledIn);
                dexOut = dexOut.add(ammUnfilledOut);
                unfilledAmounts[i + 1] = unfilledIn;
            }
            if(ammOut == 0) {
                require(dexOut > 0 && unfilledIn == 0, "CowswapRouter: INSUFFICIENT_LIQUIDITY");
                amounts[i + 1] = dexOut;
                recipients[i] = dex;
            } else {
                if(dexOut > ammOut) {
                    amounts[i + 1] = dexOut;
                    recipients[i] = dex;
                } else {
                    amounts[i + 1] = ammOut;
                    recipients[i] = PancakeLibrary.pairFor(factory, path[i], path[i + 1]);
                }
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
            if(unfilledOut > 0) {
                uint ammUnfilledIn = amm_calcInAmount(path[i - 1], path[i], unfilledOut);
                unfilledAmounts[i - 1] = ammUnfilledIn;
                dexIn = dexIn.add(ammUnfilledIn);
            }
            
            if(ammIn == 0) {
                require(dexIn > 0 && unfilledOut == 0, "CowswapRouter: INSUFFICIENT_LIQUIDITY");
                amounts[i - 1] = dexIn;
                recipients[i - 1] = dex;
            } else {
                if(dexIn > 0 && dexIn < ammIn) {
                    amounts[i - 1] = dexIn;
                    recipients[i - 1] = dex;
                } else {
                    amounts[i - 1] = ammIn;
                    recipients[i - 1] = PancakeLibrary.pairFor(factory, path[i - 1], path[i]);
                }
            }
        }
    }

    function fastAddLiquidity(
        address tokenA, // A is payment token
        address tokenB,
        uint amountA, 
        address to,
        uint deadline
    ) external payable ensure(deadline) onlyCOWBHolder {
        require(amountA > 0, "A_AMOUNT_IS_ZERO");
        if(isETH(tokenA)) {
            require(msg.value == amountA, "FastAddLiquidity: IIA");
        } else {
            TransferHelper.safeTransferFrom(tokenA, msg.sender, address(this), amountA);
        }
        address pair = getPair(wrap(tokenA), wrap(tokenB));
        require(pair != address(0), "NO_PAIR");

        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = wrap(tokenB);

        uint amountBOut = exactInputInternal(amountA / 2, 0, path, address(this), address(this));

        (uint amountAOptimal,) = _addLiquidity(
            wrap(tokenA),
            wrap(tokenB),
            amountA / 2,
            amountBOut,
            0,
            0
        );
        require(amountAOptimal <= amountA / 2, "FastAddLiquidity: A_AMOUNT_EXCEEDS");

        _deposit(tokenA, address(this), pair, amountAOptimal);
        _deposit(isETH(tokenB) ? WETH : tokenB, address(this), pair, amountBOut);

        uint refund = amountA.sub(amountAOptimal.add(amountA / 2));
        if(refund > 0) {
            if(isETH(tokenA)) {
                TransferHelper.safeTransferETH(to, refund);
            } else {
                TransferHelper.safeTransfer(tokenA, to, refund);
            }
        }

        IPancakePair(pair).mint(to);
    }

    function fastRemoveLiquidity(
        address tokenA,  // A is final accepted token
        address tokenB,
        uint liquidity,
        address to,
        uint deadline
    ) public ensure(deadline) onlyCOWBHolder {
        (uint amountA, uint amountB) = removeLiquidity(wrap(tokenA), wrap(tokenB), liquidity, 0, 0, address(this), deadline);
        // swap B to A
        address[] memory path = new address[](2);
        path[0] = wrap(tokenB);
        path[1] = tokenA;

        exactInputInternal(amountB, 0, path, address(this), to);

        _withdraw(tokenA, to, amountA);
    }

    function fastRemoveLiquidityWithPermit(
        address tokenA, // A is final accepted token
        address tokenB,
        uint liquidity,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external onlyCOWBHolder {
        address pair = getPair(wrap(tokenA), wrap(tokenB));
        uint value = approveMax ? uint(-1) : liquidity;
        IPancakePair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        fastRemoveLiquidity(tokenA, tokenB, liquidity, to, deadline);
    }


    function dex_calcOutAmount(address tokenIn, address tokenOut, uint amountIn) public view returns(uint, uint) {
        return IStakeDex(dex).calcOutAmount(tokenIn, tokenOut, amountIn);
    }

    function dex_calcInAmount(address tokenIn, address tokenOut, uint amountOut) public view returns(uint, uint) {
        return IStakeDex(dex).calcInAmount(tokenIn, tokenOut, amountOut);
    }

    function amm_calcOutAmount(address tokenIn, address tokenOut, uint amountIn) public view returns(uint) {
        if(IPancakeFactory(factory).getPair(tokenIn, tokenOut) == address(0)) {
            return 0;
        }
        (uint reserveIn, uint reserveOut) = PancakeLibrary.getReserves(factory, tokenIn, tokenOut);
        if(reserveIn == 0 || reserveOut == 0) {
            return 0;
        }
        return PancakeLibrary.calcOutAmount(factory, tokenIn, tokenOut, amountIn);
    }

    function amm_calcInAmount(address tokenIn, address tokenOut, uint amountOut) public view returns(uint) {
        if(IPancakeFactory(factory).getPair(tokenIn, tokenOut) == address(0)) {
            return 0;
        }
        (uint reserveIn, uint reserveOut) = PancakeLibrary.getReserves(factory, tokenIn, tokenOut);
        if(reserveIn == 0 || reserveOut == 0) {
            return 0;
        }
        return PancakeLibrary.calcInAmount(factory, tokenIn, tokenOut, amountOut);
    }
}