// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CowBaby is ERC20 {
	using SafeMath for uint256;

	uint256 public CAP = 100_000_000_000_000 * 1e18;
	
	constructor() public ERC20('Cow Baby', 'COWB') {
    _mint(msg.sender, CAP);
  }
}