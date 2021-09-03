// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

contract Validation {
	modifier ensure(uint deadline) {
      require(deadline >= block.timestamp, 'EXPIRED');
      _;
  }
}