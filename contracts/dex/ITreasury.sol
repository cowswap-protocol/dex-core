// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface ITreasury {
	function sendRewards(address user, uint256 amount) external returns(uint256 val);
	function cowb() external view returns(address);
}
