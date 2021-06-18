// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IProofOfTrade {
	function record(address user, address token, uint256 amount) external;
}
