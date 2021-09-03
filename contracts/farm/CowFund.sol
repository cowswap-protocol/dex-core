// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IWETH.sol";


contract CowFund is Ownable {
    using SafeERC20 for IERC20;

    address public wbnb;

    constructor(address _wbnb) public {
        wbnb = _wbnb;
    }

    receive() external payable {
        IWETH(wbnb).deposit{value: msg.value}();
        emit Deposit(msg.sender, msg.value, now);
    }

    function deposit(
        address token,
        uint256 amount
    ) public {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        emit Deposit(msg.sender, amount, now);
    }

    function withdraw(
        address token,
        uint256 amount,
        address to
    ) public onlyOwner {
        IERC20(token).safeTransfer(to, amount);
        emit Withdrawal(msg.sender, to, amount, now);
    }

    event Deposit(address indexed from, uint256 amount, uint256 indexed at);
    event Withdrawal(address indexed from, address indexed to, uint256 amount, uint256 indexed at);
}
