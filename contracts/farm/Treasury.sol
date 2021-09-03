// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract Treasury is Ownable {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  IERC20 public cowb;

  mapping (address => bool) public operators;

  modifier onlyOperator() {
    require(operators[msg.sender], "Not Operator");
    _; 
  }
  
  function addOperator(address user) public onlyOwner {
    operators[user] = true;
  }

  function removeOperator(address user) public onlyOwner {
    operators[user] = false;
  }

  event Reward(address indexed to, uint256 amount);


  constructor(address cowb_) public {
    cowb = IERC20(cowb_);
  }

  function sendRewards(address to, uint256 amount) external onlyOperator returns(uint256 val) {
    val = safeCowbTransfer(to, amount);
    emit Reward(to, val);
  }

  function withdraw(address token, uint256 amount, address to) public onlyOwner {
    IERC20(token).safeTransfer(to, amount);
  }

  function safeCowbTransfer(address to, uint256 amount) internal returns(uint256) {
    uint256 bal = cowb.balanceOf(address(this));
    if (amount > bal) {
      cowb.safeTransfer(to, bal);
      return bal;
    } else {
      cowb.safeTransfer(to, amount);
      return amount;
    }
  }
}