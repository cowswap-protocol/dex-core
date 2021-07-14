// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface ICowBoy {
	function updateRewards() external;
	function autoEnter(address to) external;
}
