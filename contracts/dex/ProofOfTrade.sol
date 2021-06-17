// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ProofOfTrade is Ownable {
	using SafeMath for uint256;

	// date => token => daily volume
	mapping (uint256 => mapping (address => uint)) dayVolumes;

	// user => date => token => volume
	mapping (address => mapping (uint256 => mapping (address => uint))) userDayVolumes;
	
	// support tokens
	address[] public tokens;
	mapping (address => bool) public isSupportedToken;
	// date => token => point
	mapping (uint256 => mapping (address => uint256)) public tokenAllocPoints;
	uint256[] public updateTokenDates;
	

	IERC20 public cowb;

	// user => token => date[]
	mapping (address => mapping (address => uint256[])) public userDays;

	uint256[] public rewardGraces = [ 10, 10, 10, 10 ];
	uint256 public ALL_REWARDS;
	uint256 public START_DATE;
	address public router;


  modifier onlyRouter() { 
  	require (msg.sender == router, "Not Router");
  	_; 
  }

	constructor(address cowb_) public {
		cowb = IERC20(cowb_);
		updateTokenDates.push(getDate(now));
	}

	function addToken(address _token, uint256 _allocPoint) public onlyOwner {
		uint256 prevDate = updateTokenDates[updateTokenDates.length - 1];
		uint256 date = getDate(now);
		for(uint256 i = 0; i < tokens.length; i++) {
			tokenAllocPoints[date][tokens[i]] = tokenAllocPoints[prevDate][tokens[i]];
		}
		tokenAllocPoints[date][_token] = _allocPoint;

		isSupportedToken[_token] = true;
		tokens.push(_token);
		updateTokenDates.push(date);
	}

	function updateToken(address _token, uint256 _allocPoint) public onlyOwner {
		uint256 prevDate = updateTokenDates[updateTokenDates.length - 1];
		uint256 date = getDate(now);
		for(uint256 i = 0; i < tokens.length; i++) {
			tokenAllocPoints[date][tokens[i]] = tokenAllocPoints[prevDate][tokens[i]];
		}
		tokenAllocPoints[date][_token] = _allocPoint;
		updateTokenDates.push(date);
	}

	function tokenLength() public view returns(uint256) {
		return tokens.length;
	}

	function updateRewardGrace(uint256 i, uint256 val) public onlyOwner {
		rewardGraces[i] = val;
	}

	function setAllRewards(uint256 val) public onlyOwner {
		ALL_REWARDS = val;
		START_DATE = getDate(now);
	}

	function getDate(uint256 ts) public pure returns(uint256) {
		return ts.sub(ts.mod(1 days));
	}

	function calcDailyTotalReward(uint256 t) public view returns(uint256){
		uint256 today = getDate(t);
		uint256 index = today.sub(START_DATE).div(365);
		if(index >= rewardGraces.length) {
			return 0;
		}
		return ALL_REWARDS.mul(rewardGraces[index]).div(100).div(365);
	}

	function getChainId() internal pure returns (uint256) {
    uint256 chainId;
    assembly { chainId := chainid() }
    return chainId;
  }

	function setRouter(address router_) public onlyOwner {
		router = router_;
	}

	function record(address user, address token, uint256 amount) public onlyRouter {
		if(!isSupportedToken[token]) {
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
		uint256 rewards = getTokenRewards(user, token);
		require(rewards > 0, "No rewards");
		safeCowbTransfer(user, rewards);
		delete userDays[user][token];
	}

	function safeCowbTransfer(address _to, uint256 _amount) internal {
    uint256 bal = cowb.balanceOf(address(this));
    if (_amount > bal) {
      cowb.transfer(_to, bal);
    } else {
      cowb.transfer(_to, _amount);
    }
  }

	function getDayReward(address user, uint256 date, address token) public view returns(uint256) {
		if(date == getDate(now)) {
			return 0;
		}
		if(userDayVolumes[user][date][token] == 0) {
			return 0;
		}
		uint256 rate = getTokenAllocRate(token, date);
		uint256 totalRewards = calcDailyTotalReward(date).mul(rate).div(1e18);
		uint256 rewards = userDayVolumes[user][date][token].mul(totalRewards).div(dayVolumes[date][token]);
		return rewards;
	}

	function getDateIndex(uint256 date) public view returns(uint256) {
		uint256 index = 0;
		for(uint256 i = 0; i < updateTokenDates.length; i++) {
			if(date > updateTokenDates[i]) {
				index = i;
			} else {
				break;
			}
		}
		return index;
	}

	function getTokenAllocRate(address token, uint256 date) public view returns(uint256) {
		uint256 index = getDateIndex(date);
		uint256 startDate = updateTokenDates[index];
		uint256 totalPoints = 0;
		for(uint256 i = 0; i < tokens.length; i++) {
			totalPoints = tokenAllocPoints[startDate][tokens[i]].add(totalPoints);
		}
		if(totalPoints == 0) {
			return 0;
		}
		return tokenAllocPoints[startDate][token].mul(1e18).div(totalPoints);
	}


	function getTokenRewards(address user, address token) public view returns(uint256) {
		uint256 rewards = 0;
		uint256[] storage _days = userDays[user][token];
		if(_days.length == 0) {
			return 0;
		}

		uint256 today = getDate(now);
		uint256 size = _days.length;
		if(_days[_days.length - 1] == today) {
			size = size - 1;
		}

		for(uint256 i = 0; i < size; i++) {
			rewards = getDayReward(user, _days[i], token).add(rewards);
		}
		return rewards;
	}

	function getTodayRewards(address user, address token) public view returns(uint256) {
		uint256 startDate = updateTokenDates[updateTokenDates.length - 1];
		uint256 totalPoints = 0;
		for(uint256 i = 0; i < tokens.length; i++) {
			totalPoints = tokenAllocPoints[startDate][tokens[i]].add(totalPoints);
		}
		if(totalPoints == 0) {
			return 0;
		}
		uint256 rate = tokenAllocPoints[startDate][token].mul(1e18).div(totalPoints);
		uint256 today = getDate(now);

		uint256 totalRewards = calcDailyTotalReward(today).mul(rate).div(1e18);
		if(dayVolumes[today][token] == 0) {
			return 0;
		}

		uint256 rewards = userDayVolumes[user][today][token].mul(totalRewards).div(dayVolumes[today][token]);
		return rewards;
	}
}