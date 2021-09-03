// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IStakeDex {
    function swap(
        address tokenIn, 
        address tokenOut,
        address to,
        address refundTo
    ) external returns(uint256 amountOut, uint256 amountReturn);

    function calcInAmount(
        address tokenIn, 
        address tokenOut, 
        uint amountOut
    ) external view returns(uint256 amountIn, uint256 amountReturn);

    function calcOutAmount(
        address tokenIn, 
        address tokenOut, 
        uint amountIn
    ) external view returns(uint256 amountOut, uint256 amountReturn);
}
