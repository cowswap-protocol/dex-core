// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;


interface IStakeDex {
	function pairs(address tokenIn, address tokenOut) external view 
	returns(uint256 id, int8 decimals, uint256[] memory prices, uint256[] memory depths);
}

interface IFactory {
	function getPair(address tokenA, address tokenB) external view returns (address pair);
}
interface IPair {
	function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract PairHelper {

	address public factory;
	address public dex;

	struct Reserve {
		address pair;
		uint reserve0;
		uint reserve1;
	}

	struct Path {
		uint256 id;
		int8 decimals;
    uint256[] prices;
    uint256[] depths;
	}

	address public dev;

	constructor(address _dex, address _factory) public {
		dev = msg.sender;
		dex = _dex;
		factory = _factory;
	}

	function setDex(address _dex) external {
		require(msg.sender == dev, "!dev");
		dex = _dex;
	}

	function setFactory(address _factory) external {
		require(msg.sender == dev, "!dev");
		factory = _factory;
	}

	function getReservesAndDepths(address tokenA, address tokenB)
	public 
	view 
	returns(
		Reserve memory reserve,
		Path memory pathAB,
		Path memory pathBA
	) 
	{
		address pair = IFactory(factory).getPair(tokenA, tokenB);
		uint256 reserve0 = 0;
		uint256 reserve1 = 0;
		if(pair != address(0)) {
			(reserve0, reserve1, ) = IPair(pair).getReserves();
		}
		reserve = Reserve({
			pair: pair,
			reserve0: reserve0,
			reserve1: reserve1
		});
		(pathAB.id, pathAB.decimals, pathAB.prices, pathBA.depths) = IStakeDex(dex).pairs(tokenA, tokenB);
		(pathBA.id, pathBA.decimals, pathBA.prices, pathBA.depths) = IStakeDex(dex).pairs(tokenB, tokenA);
	}
}
