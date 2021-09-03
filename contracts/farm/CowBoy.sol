// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./ITreasury.sol";

contract CowBoy is ERC20("CowBoy", "COWBOY"), Ownable {
    using SafeMath for uint256;
    IERC20 public cowb;
    ITreasury public treasury;

    uint256 public rewardsPerBlock = 285388 * 1e18;
    uint256 public lastRewardBlock;

    uint256 public startBlock;
    uint256 public endBlock;

    uint256 public blocksPerYear = 10512000;

    event RewardAdded(uint256 amount);

    constructor(uint256 _startBlock, address _treasury) public {
        startBlock = _startBlock;
        endBlock = _startBlock + 4 * blocksPerYear;
        lastRewardBlock = _startBlock;
        treasury = ITreasury(_treasury);
        cowb = IERC20(treasury.cowb());
    }

    function getRewards(uint256 from, uint256 to) public view returns(uint256) {
        require(from <= to, "From must be greater than to");

        if(to < startBlock) {
            return 0;
        } else if(from < startBlock && to <= endBlock) {
            return to.sub(startBlock).mul(rewardsPerBlock);
        } else if(from >= startBlock && to <= endBlock) {
            return to.sub(from).mul(rewardsPerBlock);
        } else if(from < endBlock && to > endBlock) {
            return endBlock.sub(from).mul(rewardsPerBlock);
        } else {
            return 0;
        }
    }

    function updateRewardsPerBlock(uint256 val_) public onlyOwner {
        updateRewards();
        rewardsPerBlock = val_;
    }

    function updateRewards() public {
        if (block.number > lastRewardBlock) {
            if(totalSupply() > 0) {
                uint256 rewards = getRewards(lastRewardBlock, block.number);
                if (rewards > 0) {
                    uint256 rewarded = treasury.sendRewards(address(this), rewards);
                    emit RewardAdded(rewarded);
                }
            }
            lastRewardBlock = block.number;
        }
    }

    function price() public view returns(uint256) {
        uint256 rewards = getRewards(lastRewardBlock, block.number);
        uint256 totalTokens = cowb.balanceOf(address(this)).add(rewards);
        uint256 totalShares = totalSupply();
        return totalTokens.mul(1e18).div(totalShares);
    }

    function enter(uint256 _amount) public {
        updateRewards();
        require(_amount > 0, "zero");
        uint256 totalTokens = cowb.balanceOf(address(this));
        uint256 totalShares = totalSupply();

        if (totalShares == 0 || totalTokens == 0) {
            _mint(msg.sender, _amount);
        } 
        else {
            uint256 what = _amount.mul(totalShares).div(totalTokens);
            _mint(msg.sender, what);
        }
        cowb.transferFrom(msg.sender, address(this), _amount);
    }

    function leave(uint256 _share) public {
        updateRewards();
        require(_share > 0, "zero");
        uint256 totalShares = totalSupply();
        uint256 what = _share.mul(cowb.balanceOf(address(this))).div(totalShares);
        _burn(msg.sender, _share);
        cowb.transfer(msg.sender, what);
    }
}