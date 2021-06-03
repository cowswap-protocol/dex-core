// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CowDao {
	using SafeMath for uint256;

	IERC20 public cowb;

	function lock(uint256 amount) public {
		cowb.transferFrom(msg.sender, address(this), amount);
	}

	function redeem() public {

	}
}