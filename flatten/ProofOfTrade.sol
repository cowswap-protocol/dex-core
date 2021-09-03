// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/math/SafeMath.sol



pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @openzeppelin/contracts/GSN/Context.sol



pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.6.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/dex/ITreasury.sol


pragma solidity ^0.6.12;

interface ITreasury {
	function sendRewards(address user, uint256 amount) external returns(uint256 val);
	function cowb() external view returns(address);
}

// File: contracts/dex/ProofOfTrade.sol


pragma solidity ^0.6.12;





contract ProofOfTrade is Ownable {
	using SafeMath for uint256;

	IERC20 public cowb;
	ITreasury public treasury;

	// date => token => volume
	mapping (uint256 => mapping (address => uint)) public dayVolumes;

	// user => date => token => volume
	mapping (address => mapping (uint256 => mapping (address => uint))) public userDayVolumes;
	
	address public router;
	uint256 public potThreshold = 0;
	uint256 public fastLiquidityThreshold = 0;

	mapping (address => uint256) public traded;
	bool public tradingEnable = true;
	uint256 public tradingRewards = 1_000_000 * 1e18;
	uint256 public totalTradingRewarded = 0;
	uint256 public totalTradingRewardMax = 100_000_000_000 * 1e18;
	

	struct PoolInfo {
		address token;
		uint256 dailyRewards;
		uint256 userDailyMax;
		uint256 startTime;
		uint256 endTime;
	}
	mapping (address => PoolInfo) public pools;

	address[] private poolTokens;

	

	// user => token => date[]
	mapping (address => mapping (address => uint256[])) public userDays;


  modifier onlyRouter() { 
  	require (msg.sender == router, "Not Router");
  	_; 
  }

  modifier onlyHolder(address holder) { 
  	require (cowb.balanceOf(holder) >= potThreshold, "Not COWB holder"); 
  	_; 
  }
  
	constructor(address treasury_) public {
		treasury = ITreasury(treasury_);
		cowb = IERC20(treasury.cowb());
	}

	function setPool(address _token, uint256 _dailyRewards, uint256 _userDailyMax, uint256 _startTime, uint256 _endTime) public onlyOwner {
		pools[_token] = PoolInfo({
			token: _token,
			dailyRewards: _dailyRewards,
			userDailyMax: _userDailyMax,
			startTime: _startTime,
			endTime: _endTime
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
		uint256 userDailyMax,
		uint256 startTime,
		uint256 endTime
	) {
		PoolInfo memory pool = pools[poolTokens[index]];
		token = pool.token;
		dailyRewards = pool.dailyRewards;
		userDailyMax = pool.userDailyMax;
		startTime = pool.startTime;
		endTime = pool.endTime;
	}


	function setTreasury(address newTreasury) public onlyOwner {
		treasury = ITreasury(newTreasury);
	}

	function setFastLiquidityThreshold(uint256 val) public onlyOwner {
		fastLiquidityThreshold = val;
	}
	function setPotThreshold(uint256 val) public onlyOwner {
		potThreshold = val;
	}

	function setTradingEnable(bool b) public onlyOwner {
		tradingEnable = b;
	}

	function setTradingRewards(uint256 val) public onlyOwner {
		tradingRewards = val;
	}

	function setTotalTradingRewardMax(uint256 max) public onlyOwner {
		totalTradingRewardMax = max;
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

	function _giveaway(address user) internal {
		if(!tradingEnable) {
			return;
		}
		if(totalTradingRewarded >= totalTradingRewardMax) {
			return;
		}

		traded[user] += 1;
		if(traded[user] == 1) {
			treasury.sendRewards(user, tradingRewards);
			totalTradingRewarded = totalTradingRewarded.add(tradingRewards);
		}

		if(traded[user] == 5) {
			treasury.sendRewards(user, tradingRewards.mul(5));
			totalTradingRewarded = totalTradingRewarded.add(tradingRewards.mul(5));
		}
	}

	function record(address user, address token, uint256 amount) public onlyRouter {
		_giveaway(user);

		if(!isMiningToken(token)) {
			return;
		}

		if(cowb.balanceOf(user) < potThreshold) {
			return;
		}
		
		if(pools[token].startTime > now || pools[token].endTime < now) {
			return;
		}

		uint256 date = getDate(now);

		if(pools[token].userDailyMax > 0) {
			if(userDayVolumes[user][date][token] >= pools[token].userDailyMax) {
				return;
			}
			if(userDayVolumes[user][date][token].add(amount) > pools[token].userDailyMax) {
				amount = pools[token].userDailyMax.sub(userDayVolumes[user][date][token]);
			}
		}
		
		dayVolumes[date][token] = dayVolumes[date][token].add(amount);
		userDayVolumes[user][date][token] = userDayVolumes[user][date][token].add(amount);
		
		if(userDays[user][token].length == 0) {
			userDays[user][token].push(date);
		} else if(userDays[user][token][userDays[user][token].length - 1] < date) {
			userDays[user][token].push(date);
		}
	}

	// Havest
	function claim(address user, address token) public onlyHolder(user) {
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
		return cowb.balanceOf(user) >= fastLiquidityThreshold;
	}
}
