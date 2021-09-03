// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./ITreasury.sol";

interface IMigrator {
    function migrate(IERC20 token) external returns (IERC20);
}

contract CowFarm is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of Rewards
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accRewardPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accRewardPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. Rewards to distribute per block.
        uint256 lastRewardBlock;  // Last block number that Rewards distribution occurs.
        uint256 accRewardPerShare; // Accumulated Rewards per share, times 1e12. See below.
    }

    IERC20 public cowb;

    ITreasury public treasury;


    // Block number when bonus  period ends.
    // uint256 public bonusEndBlock;
    // Reward tokens created per block.
    uint256 private rewardsPerBlock;
    // Bonus muliplier
    // uint256 public BONUS_MULTIPLIER = 1;
    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigrator public migrator;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when mining starts.
    uint256 public startBlock;

    uint256 public endBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        address _treasury,
        uint256 _rewardsPerBlock,
        uint256 _startBlock,
        uint256 _endBlock
    ) public {
        treasury = ITreasury(_treasury);
        cowb = IERC20(treasury.cowb());
        rewardsPerBlock = _rewardsPerBlock;
        startBlock = _startBlock;
        endBlock = _endBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accRewardPerShare: 0
        }));
    }

    // Update the given pool's allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    function updateRewardsPerBlock(uint256 _rewardsPerBlock) public onlyOwner {
        rewardsPerBlock = _rewardsPerBlock;
        massUpdatePools();
    }

    // Set the migrator contract. Can only be called by the owner.
    function setMigrator(IMigrator _migrator) public onlyOwner {
        migrator = _migrator;
    }

    // Migrate lp token to another lp contract. Can be called by anyone. We trust that migrator contract is good.
    function migrate(uint256 _pid) public {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfo[_pid];
        IERC20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        IERC20 newLpToken = migrator.migrate(lpToken);
        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        pool.lpToken = newLpToken;
    }

    function getRewards(uint256 _from, uint256 _to) public view returns(uint256) {
        require(_from <= _to, "From must be greater than to");
        if(_to < startBlock) {
            return 0;
        } else if(_from < startBlock && _to <= endBlock) {
            return _to.sub(startBlock).mul(rewardsPerBlock);
        } else if(_from >= startBlock && _to <= endBlock) {
            return _to.sub(_from).mul(rewardsPerBlock);
        } else if(_from < endBlock && _to > endBlock) {
            return endBlock.sub(_from).mul(rewardsPerBlock);
        } else {
            return 0;
        }
    }

    // Return reward multiplier over the given _from to _to block.
    // function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
    //     if (_to <= bonusEndBlock) {
    //         return _to.sub(_from).mul(BONUS_MULTIPLIER);
    //     } else if (_from >= bonusEndBlock) {
    //         return _to.sub(_from);
    //     } else {
    //         return bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(
    //             _to.sub(bonusEndBlock)
    //         );
    //     }
    // }

    function pendingRewards(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            // uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            // uint256 rewards = multiplier.mul(rewardsPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            uint256 rewards = getRewards(pool.lastRewardBlock, block.number).mul(pool.allocPoint).div(totalAllocPoint);

            accRewardPerShare = accRewardPerShare.add(rewards.mul(1e12).div(lpSupply));
        }

        return user.amount.mul(accRewardPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        // uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        // uint256 rewards = multiplier.mul(getRewardsPerBlock()).mul(pool.allocPoint).div(totalAllocPoint);
        uint256 rewards = getRewards(pool.lastRewardBlock, block.number).mul(pool.allocPoint).div(totalAllocPoint);
        uint256 rewarded = treasury.sendRewards(address(this), rewards);

        pool.accRewardPerShare = pool.accRewardPerShare.add(rewarded.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }


    // Deposit LP tokens to Farm for token allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeTransfer(msg.sender, pending);
            }
        }
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from Fram.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safeTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Safe transfer function, just in case if rounding error causes pool to not have enough Tokens.
    function safeTransfer(address _to, uint256 _amount) internal {
        uint256 _bal = cowb.balanceOf(address(this));
        if (_amount > _bal) {
            cowb.transfer(_to, _bal);
        } else {
            cowb.transfer(_to, _amount);
        }
    }
}
