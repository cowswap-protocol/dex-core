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

    uint256 public rewardsPerBlock = 20000 * 1e18;
    uint256 public lastRewardBlock;
    uint256 public cowbReserves;

    event RewardAdded(uint256 amount);

    constructor(uint256 _startBlock, address _treasury) public {
        lastRewardBlock = _startBlock;
        treasury = ITreasury(_treasury);
        cowb = IERC20(treasury.cowb());
    }

    function updateRewardsPerBlock(uint256 val_) public onlyOwner {
        updateRewards();
        rewardsPerBlock = val_;
    }

    function updateRewards() public {
        if (block.number > lastRewardBlock) {
            if(totalSupply() > 0) {
                uint256 rewards = block.number.sub(lastRewardBlock).mul(rewardsPerBlock);
                if (rewards > 0) {
                    uint256 rewarded = treasury.sendRewards(address(this), rewards);
                    emit RewardAdded(rewarded);
                }
            }
            lastRewardBlock = block.number;

            _updateReserves();
        }
    }

    function _updateReserves() internal {
        cowbReserves = cowb.balanceOf(address(this));
    }

    function price() public view returns(uint256) {
        uint256 rewards = block.number > lastRewardBlock ? block.number.sub(lastRewardBlock).mul(rewardsPerBlock) : 0;
        uint256 totalTokens = cowb.balanceOf(address(this)).add(rewards);
        uint256 totalShares = totalSupply();
        return totalTokens.mul(1e18).div(totalShares);
    }

    function autoEnter(address to) public {
        uint256 totalTokens = cowb.balanceOf(address(this));
        uint256 totalShares = totalSupply();        
        if(totalTokens > cowbReserves) {
            uint256 _amount = totalTokens.sub(cowbReserves);
            if (totalShares == 0 || totalTokens == 0) {
                _mint(to, _amount);
            } 
            else {
                uint256 what = _amount.mul(totalShares).div(totalTokens);
                _mint(to, what);
            }
        }
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

        _updateReserves();
    }

    function leave(uint256 _share) public {
        updateRewards();
        require(_share > 0, "zero");
        uint256 totalShares = totalSupply();
        uint256 what = _share.mul(cowb.balanceOf(address(this))).div(totalShares);
        _burn(msg.sender, _share);
        cowb.transfer(msg.sender, what);

        _updateReserves();
    }
}