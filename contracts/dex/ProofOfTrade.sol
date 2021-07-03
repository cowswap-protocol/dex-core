// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


import "./ITreasury.sol";

contract ProofOfTrade is Ownable {
	using SafeMath for uint256;

	IERC20 public cowb;
	ITreasury public treasury;

	// date => token => volume
	mapping (uint256 => mapping (address => uint)) dayVolumes;

	// user => date => token => volume
	mapping (address => mapping (uint256 => mapping (address => uint))) userDayVolumes;
	
	address public router;
	uint256 public balanceThreshold = 0;


	struct PoolInfo {
		address token;
		uint256 dailyRewards;
		uint256 startTime;
		uint256 endTime;
		uint256 fee; // base is 10000
	}
	mapping (address => PoolInfo) public pools;

	address[] private poolTokens;
	

	// user => token => date[]
	mapping (address => mapping (address => uint256[])) public userDays;


  modifier onlyRouter() { 
  	require (msg.sender == router, "Not Router");
  	_; 
  }

	constructor(address cowb_, address treasury_) public {
		cowb = IERC20(cowb_);
		treasury = ITreasury(treasury_);
	}

	function setPool(address _token, uint256 _dailyRewards, uint256 _startTime, uint256 _endTime, uint256 _fee) public onlyOwner {
		pools[_token] = PoolInfo({
			token: _token,
			dailyRewards: _dailyRewards,
			startTime: _startTime,
			endTime: _endTime,
			fee: _fee
		});
		bool pooled = false;
		for(uint256 i = 0; i < poolTokens.length; i++) {
			if(poolTokens[i] == _token) {
				pooled = true;
				break;
			}
		}
		if(!pooled) {
			poolTokens.push(_token);	
		}
	}

	function getPool(uint256 index) public view returns(
		address token,
		uint256 dailyRewards,
		uint256 startTime,
		uint256 endTime,
		uint256 fee
	) {
		PoolInfo memory pool = pools[poolTokens[index]];
		token = pool.token;
		dailyRewards = pool.dailyRewards;
		startTime = pool.startTime;
		endTime = pool.endTime;
		fee = pool.fee;
	}


	function setTreasury(address newTreasury) public onlyOwner {
		treasury = ITreasury(newTreasury);
	}

	function setBalanceThreshold(uint256 val) public onlyOwner {
		balanceThreshold = val;
	}

	function setRouter(address router_) public onlyOwner {
		router = router_;
	}


	function isMiningToken(address token) public view returns(bool) {
		return pools[token].token != address(0);
	}

	function poolLength() public view returns(uint256) {
		return poolTokens.length;
	}

	function getPoolTokens() public view returns(address[] memory) {
		return poolTokens;
	}

	function getDate(uint256 ts) public pure returns(uint256) {
		return ts.sub(ts.mod(1 days));
	}


	function record(address user, address token, uint256 amount) public onlyRouter {
		if(!isMiningToken(token) || !validCOWBHolder(user)) {
			return;
		}

		uint256 date = getDate(now);
		dayVolumes[date][token] = dayVolumes[date][token].add(amount);
		userDayVolumes[user][date][token] = userDayVolumes[user][date][token].add(amount);

		if(userDays[user][token].length == 0) {
			userDays[user][token].push(date);
		} else if(userDays[user][token][userDays[user][token].length - 1] < date) {
			userDays[user][token].push(date);
		}
	}

	function claim(address user, address token) public {
		(, uint256 rewards) = getRewards(user, token);
		require(rewards > 0, "No rewards");
		treasury.sendRewards(user, rewards);
		if(userDays[user][token][userDays[user][token].length - 1] == getDate(now)) {
			userDays[user][token] = [ getDate(now) ];
		} else {
			delete userDays[user][token];
		}
	}

	function getDayReward(address user, uint256 date, address token) public view returns(uint256) {

		date = getDate(date);

		if(userDayVolumes[user][date][token] == 0) {
			return 0;
		}

		PoolInfo memory pool = pools[token];
		uint256 rewards = 0;

		if(pool.startTime <= date && pool.endTime >= date) {
			rewards = userDayVolumes[user][date][token].mul(pool.dailyRewards).div(dayVolumes[date][token]);	
		}

		return rewards;
	}



	function getRewards(address user, address token) public view returns(uint256 pending, uint256 rewards) {
		uint256[] storage _days = userDays[user][token];
		if(_days.length == 0) {
			return (0, 0);
		}
		uint256 today = getDate(now);

		for(uint256 i = 0; i < _days.length; i++) {
			if(_days[i] < today) {
				rewards = getDayReward(user, _days[i], token).add(rewards);	
			} else {
				pending = getDayReward(user, _days[i], token);
			}
		}
	}

	function validCOWBHolder(address user) public view returns(bool) {
		return cowb.balanceOf(user) >= balanceThreshold;
	}
}