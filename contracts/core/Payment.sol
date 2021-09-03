// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;


import "./IERC20.sol";
import "../interfaces/IWETH.sol";
import "../lib/TransferHelper.sol";

contract Payment {
	address public ETH = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

	address public WETH;

	constructor(address _WETH) public {
		WETH = _WETH;
	}

	receive() external payable {
  }

	function _deposit(address token, address payer, address recipient, uint amount) internal {
      if(payer == recipient) { return; }
      
      if(token == ETH && address(this).balance >= amount) {
        IWETH(WETH).deposit{value: amount}();
        assert(IWETH(WETH).transfer(recipient, amount));
      } else if(payer == address(this)) {
        TransferHelper.safeTransfer(token, recipient, amount);
      } else {
        TransferHelper.safeTransferFrom(token, payer, recipient, amount);
      }
  }

  function _withdraw(address token, address to, uint amount) internal {
      if(token == ETH) {
          uint balance = IERC20(WETH).balanceOf(address(this));
          require(balance >= amount, "Insufficient WETH");
          if(amount > 0) {
            IWETH(WETH).withdraw(amount);
            TransferHelper.safeTransferETH(to, amount);
          }
      } else {
          TransferHelper.safeTransfer(token, to, amount);
      }
  }

  function wrap(address token) internal view returns(address) {
      return token == ETH ? WETH : token;
  }

  function isETH(address token) internal view returns(bool) {
      return token == ETH;
  }
}