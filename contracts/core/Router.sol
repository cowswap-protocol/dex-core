// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

// import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


import "./StakeDex.sol";


contract Router {
    using SafeMath for uint256;
    // using SafeERC20 for IERC20;

    address public dex; 

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'EXPIRED');
        _;
    }

    constructor(address _dex) public {
        dex = _dex;
    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external ensure(deadline) returns (uint[] memory amounts) {
        amounts = getAmountsOut(amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');

        IERC20(path[0]).transferFrom(msg.sender, dex, amountIn);

        for(uint i; i < path.length - 1; i++) {
            address _to = i < path.length - 2 ? dex : to;
            StakeDex(dex).swap(path[i], path[i + 1], 0, _to);
        }
    }

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external ensure(deadline) returns (uint[] memory amounts) {
        amounts = getAmountsIn(amountOut, path);
        require(amounts[0] <= amountInMax, 'EXCESSIVE_INPUT_AMOUNT');
        IERC20(path[0]).transferFrom(msg.sender, dex, amounts[0]);

        for(uint i; i < path.length - 1; i++) {
            address _to = i < path.length - 2 ? dex : to;
            StakeDex(dex).swap(path[i], path[i + 1], 0, _to);
        }
    }


    function getAmountsOut(uint amountIn, address[] memory path) public view returns(uint[] memory amounts) {
        require(path.length >= 2, 'INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint amountOut, ) = StakeDex(dex).calcOutAmount(path[i], path[i + 1], amounts[i]);
            amounts[i + 1] = amountOut;
        }
    }

    function getAmountsIn(uint256 amountOut, address[] memory path) public view returns(uint[] memory amounts) {
        require(path.length >= 2, 'INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint amountIn, ) = StakeDex(dex).calcOutAmount(path[i - 1], path[i], amounts[i]);
            amounts[i - 1] = amountIn;
        }
    }

}