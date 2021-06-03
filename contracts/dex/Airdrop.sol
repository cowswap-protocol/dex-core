// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Airdrop is Ownable {
	using SafeMath for uint256;

	IERC20 public cowb;

	constructor(address cowb_) public {
		cowb = IERC20(cowb_);
	}

	function distribute(address[] memory users, uint256 amount) public onlyOwner {
		for(uint256 i = 0; i < users.length; i++) {
			cowb.transfer(users[i], amount);
		}
	}
}