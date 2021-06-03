// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CowMigration is Ownable {
	using SafeMath for uint256;

  mapping (address => uint) public rates;
  
  address public cowb;
  address public milk;
  address public cox;

  address public dead = address(0x000000000000000000000000000000000000dEaD);

  constructor(address cowb_, address milk_, address cox_) public {
    cowb = cowb_;
    milk = milk_;
    cox = cox_;
  }

  // _rate is based on 1e18, 1 => 1e18, 0.5 => 5e17
  function setRate(address _token, uint256 _rate) public onlyOwner {
    rates[_token] == _rate;
  }

  function migrate(address from, uint256 amount) public {
    require(from == milk || from == cox, "Forbidden");
    require(rates[from] > 0, "Rate is invalid");

    uint256 amountOut = amount.mul(rates[from]).div(1e18);
    IERC20(from).transferFrom(msg.sender, address(this), amount);
    IERC20(from).transfer(dead, amount);
    IERC20(cowb).transfer(msg.sender, amountOut);
  }
}