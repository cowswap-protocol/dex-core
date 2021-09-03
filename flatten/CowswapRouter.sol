// SPDX-License-Identifier: GPL-2.0-or-later

// File: contracts/interfaces/IPancakeFactory.sol



pragma solidity >=0.5.0;

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;

    function INIT_CODE_PAIR_HASH() external view returns (bytes32);
}

// File: contracts/interfaces/IPancakePair.sol



pragma solidity >=0.6.0;

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

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

// File: contracts/lib/PancakeLibrary.sol



pragma solidity >=0.6.0;



// library SafeMath {
//     function add(uint x, uint y) internal pure returns (uint z) {
//         require((z = x + y) >= x, 'ds-math-add-overflow');
//     }

//     function sub(uint x, uint y) internal pure returns (uint z) {
//         require((z = x - y) <= x, 'ds-math-sub-underflow');
//     }

//     function mul(uint x, uint y) internal pure returns (uint z) {
//         require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
//     }
// }

library PancakeLibrary {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'PancakeLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'PancakeLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'00fb7f630766e6a796048ea87d01acd3068e8ff67d078148a3fa3f4a84f69bd5' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        pairFor(factory, tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IPancakePair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'PancakeLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'PancakeLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(9975);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(10000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'PancakeLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(10000);
        uint denominator = reserveOut.sub(amountOut).mul(9975);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PancakeLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PancakeLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }

    function calcInAmount(
        address factory,
        address tokenIn, 
        address tokenOut, 
        uint amountOut
    ) internal view returns(uint) {
        (uint reserveIn, uint reserveOut) = getReserves(factory, tokenIn, tokenOut);
        return getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function calcOutAmount(
        address factory,
        address tokenIn, 
        address tokenOut, 
        uint amountIn
    ) internal view returns(uint) {
        (uint reserveIn, uint reserveOut) = getReserves(factory, tokenIn, tokenOut);
        return getAmountOut(amountIn, reserveIn, reserveOut);
    }
}

// File: contracts/core/Validation.sol


pragma solidity ^0.6.12;

contract Validation {
	modifier ensure(uint deadline) {
      require(deadline >= block.timestamp, 'EXPIRED');
      _;
  }
}

// File: contracts/core/IERC20.sol


pragma solidity ^0.6.12;
interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/interfaces/IWETH.sol


pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// File: contracts/lib/TransferHelper.sol


pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// File: contracts/core/Payment.sol


pragma solidity ^0.6.12;




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

// File: contracts/core/Liquidity.sol


pragma solidity ^0.6.12;






contract Liquidity is Validation, Payment {
    using SafeMath for uint256;

    address public factory;

    constructor(address _factory, address _WETH) public Payment(_WETH) {
        factory = _factory;
    }


    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal virtual returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        if (IPancakeFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            IPancakeFactory(factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = PancakeLibrary.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = PancakeLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'CowswapRouter: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = PancakeLibrary.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'CowswapRouter: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external payable ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(
            wrap(tokenA),
            wrap(tokenB), 
            amountADesired, 
            amountBDesired, 
            amountAMin, 
            amountBMin
        );
        address pair = PancakeLibrary.pairFor(
            factory, 
            wrap(tokenA), 
            wrap(tokenB)
        );
        _deposit(tokenA, msg.sender, pair, amountA);
        _deposit(tokenB, msg.sender, pair, amountB);
        liquidity = IPancakePair(pair).mint(to);
    }

    function _removeLiquidityInternal(
        address tokenA,
        address tokenB,
        uint liquidity,
        address to
    ) internal returns(uint amountA, uint amountB) {
        address pair = PancakeLibrary.pairFor(factory, wrap(tokenA), wrap(tokenB));
        IPancakePair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        address _to = (tokenA == ETH || tokenB == ETH) ? address(this) : to;
        uint amountABefore = IERC20(wrap(tokenA)).balanceOf(_to);
        uint amountBBefore = IERC20(wrap(tokenB)).balanceOf(_to);
        IPancakePair(pair).burn(_to);
        amountA = IERC20(wrap(tokenA)).balanceOf(_to).sub(amountABefore);
        amountB = IERC20(wrap(tokenB)).balanceOf(_to).sub(amountBBefore);
    }


    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public ensure(deadline) returns (uint amountA, uint amountB) {
        (amountA, amountB) = _removeLiquidityInternal(tokenA, tokenB, liquidity, to);
        require(amountA >= amountAMin, 'CowswapRouter: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'CowswapRouter: INSUFFICIENT_B_AMOUNT');

        if(tokenA == ETH || tokenB == ETH) {
            _withdraw(tokenA, to, amountA);
            _withdraw(tokenB, to, amountB);
        }
    }

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB) {
        IPancakePair(PancakeLibrary.pairFor(factory, wrap(tokenA), wrap(tokenB))).permit(msg.sender, address(this), approveMax ? uint(-1) : liquidity, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }
}

// File: contracts/core/IStakeDex.sol


pragma solidity ^0.6.12;

interface IStakeDex {
    function swap(
        address tokenIn, 
        address tokenOut,
        address to,
        address refundTo
    ) external returns(uint256 amountOut, uint256 amountReturn);

    function calcInAmount(
        address tokenIn, 
        address tokenOut, 
        uint amountOut
    ) external view returns(uint256 amountIn, uint256 amountReturn);

    function calcOutAmount(
        address tokenIn, 
        address tokenOut, 
        uint amountIn
    ) external view returns(uint256 amountOut, uint256 amountReturn);
}

// File: contracts/core/CowswapRouter.sol


pragma solidity ^0.6.12;




interface IProofOfTrade {
    function validCOWBHolder(address user) external view returns(bool);
    function record(address user, address token, uint256 amount) external;
}

contract CowswapRouter is Liquidity {
    using SafeMath for uint256;

    address public dex; 
    IProofOfTrade public pot;

    modifier onlyCOWBHolder() { 
        require(pot.validCOWBHolder(msg.sender), "Not COWB Holder"); 
        _; 
    }
    

    constructor(address _dex, address _factory, address _WETH, address _pot) public Liquidity(_factory, _WETH) {
        dex = _dex;
        pot = IProofOfTrade(_pot);
    }

    function ammSwap(address input, address output, address to) internal returns(uint) {
        (address token0,) = PancakeLibrary.sortTokens(input, output);
        IPancakePair pair = IPancakePair(PancakeLibrary.pairFor(factory, input, output));
        uint amountInput;
        uint amountOutput;
        { // scope to avoid stack too deep errors
        (uint reserve0, uint reserve1,) = pair.getReserves();
        (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
        amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
        amountOutput = PancakeLibrary.getAmountOut(amountInput, reserveInput, reserveOutput);
        }
        (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
        pair.swap(amount0Out, amount1Out, to, new bytes(0));
        return amountOutput;
    }

    function dexSwap(address tokenIn, address tokenOut, address to) internal {
        (,uint amountReturn) = IStakeDex(dex).swap(tokenIn, tokenOut, to, getPair(tokenIn, tokenOut));
        if(amountReturn > 0) {
            ammSwap(tokenIn, tokenOut, to);
        }
    }

    function getPair(address tokenIn, address tokenOut) internal view returns(address) {
        return IPancakeFactory(factory).getPair(tokenIn, tokenOut);
    }

    function exactInputInternal(
        uint amountIn,
        uint amountOutMin,
        address[] memory path,
        address payer,
        address to
    ) internal returns(uint amountOut) {
        bool isEtherIn = isETH(path[0]);
        bool isEtherOut = isETH(path[path.length - 1]);
        if(isEtherIn) {
            path[0] = WETH;
        }
        if(isEtherOut) {
            path[path.length - 1] = WETH;
        }

        address[] memory recipients;
        uint[] memory amounts;
        (amounts,,recipients) = getAmountsOut(amountIn, path, to);
        require(amounts[path.length - 1] >= amountOutMin, "CowswapRouter: IOA"); // INSUFFICIENT_OUTPUT_AMOUNT
        
        if(isEtherOut) {
            recipients[path.length - 1] = address(this);
        }

        _deposit(isEtherIn ? ETH : path[0], payer, recipients[0], amounts[0]);

        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(recipients[recipients.length - 1]);

        for(uint i; i < path.length - 1; i++) {
            if(recipients[i] == dex) {
                dexSwap(path[i], path[i + 1], recipients[i + 1]);
            } else {
                ammSwap(path[i], path[i + 1], recipients[i + 1]);
            }
        }
        amountOut = IERC20(path[path.length - 1]).balanceOf(recipients[recipients.length - 1]).sub(balanceBefore);

        if(isEtherOut) {
            _withdraw(ETH, to, amountOut);
        }

        pot.record(msg.sender, path[path.length - 1], amountOut.mul(path.length - 1));
    }

    function exactOutputInternal(
        uint amountOut,
        uint amountInMax,
        address[] memory path,
        address payer,
        address to
    ) internal returns(uint amountIn, uint actualAmountOut) {
        bool isEtherIn = isETH(path[0]);
        bool isEtherOut = isETH(path[path.length - 1]);
        if(isEtherIn) {
            path[0] = WETH;
        }
        if(isEtherOut) {
            path[path.length - 1] = WETH;
        }
        address[] memory recipients;
        uint[] memory amounts;
        (amounts,,recipients) = getAmountsIn(amountOut, path, to);
        require(amountInMax >= amounts[0], "CowswapRouter: EIA"); // EXCESSIVE_INPUT_AMOUNT

        if(isEtherOut) {
            recipients[path.length - 1] = address(this);
        }

        _deposit(isEtherIn ? ETH : path[0], payer, recipients[0], amounts[0]);

        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(recipients[recipients.length - 1]);

        for(uint i; i < path.length - 1; i++) {
            if(recipients[i] == dex) {
                dexSwap(path[i], path[i + 1], recipients[i + 1]);
            } else {
                ammSwap(path[i], path[i + 1], recipients[i + 1]);
            }
        }
        
        actualAmountOut = IERC20(path[path.length - 1]).balanceOf(recipients[recipients.length - 1]).sub(balanceBefore);
        amountIn = amounts[0];

        if(isEtherOut) {
            _withdraw(ETH, to, actualAmountOut);
        }

        pot.record(msg.sender, path[path.length - 1], actualAmountOut.mul(path.length - 1));
    }

    function exactInput(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) 
    external 
    payable 
    ensure(deadline)
    returns (uint amountOut)
    {   
       amountOut = exactInputInternal(amountIn, amountOutMin, path, msg.sender, to);
       require(amountOut >= amountOutMin, "ExactInput: IOA");
    }

    function exactOutput(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) 
    external 
    payable 
    ensure(deadline) 
    returns(uint amountIn)
    {
        uint actualAmountOut;
        (amountIn, actualAmountOut) = exactOutputInternal(amountOut, amountInMax, path, msg.sender, to);
        require(actualAmountOut >= amountOut, "ExactOutput: IOA");
        if(isETH(path[0]) && msg.value > amountIn) {
            TransferHelper.safeTransferETH(msg.sender, msg.value - amountIn);
        }
    }

    function exactOutputSupportingFeeOnTransferTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) 
    external 
    payable 
    ensure(deadline) 
    returns(uint amountIn)
    {
        (amountIn,) = exactOutputInternal(amountOut, amountInMax, path, msg.sender, to);
        if(isETH(path[0]) && msg.value > amountIn) {
            TransferHelper.safeTransferETH(msg.sender, msg.value - amountIn);
        }
    }



    function getAmountsOut(
        uint amountIn, 
        address[] memory path, 
        address to
    ) public view returns(
        uint[] memory amounts, 
        uint[] memory unfilledAmounts,
        address[] memory recipients
    ) {
        amounts = new uint[](path.length);
        unfilledAmounts = new uint[](path.length);

        amounts[0] = amountIn;
        recipients = new address[](path.length);
        recipients[path.length - 1] = to;

        for(uint i; i < path.length - 1; i++) {
            uint ammOut = amm_calcOutAmount(path[i], path[i + 1], amounts[i]);

            (uint dexOut, uint unfilledIn) = dex_calcOutAmount(path[i], path[i + 1], amounts[i]);
            if(unfilledIn > 0) {
                uint ammUnfilledOut = amm_calcOutAmount(path[i], path[i + 1], unfilledIn);
                dexOut = dexOut.add(ammUnfilledOut);
                unfilledAmounts[i + 1] = unfilledIn;
            }
            if(ammOut == 0) {
                require(dexOut > 0 && unfilledIn == 0, "CowswapRouter: INSUFFICIENT_LIQUIDITY");
                amounts[i + 1] = dexOut;
                recipients[i] = dex;
            } else {
                if(dexOut > ammOut) {
                    amounts[i + 1] = dexOut;
                    recipients[i] = dex;
                } else {
                    amounts[i + 1] = ammOut;
                    recipients[i] = PancakeLibrary.pairFor(factory, path[i], path[i + 1]);
                }
            }
        }
    }

    function getAmountsIn(
        uint amountOut, 
        address[] memory path, 
        address to
    ) public view returns(
        uint[] memory amounts, 
        uint[] memory unfilledAmounts,
        address[] memory recipients
    ) {
        amounts = new uint[](path.length);
        amounts[path.length - 1] = amountOut;

        unfilledAmounts = new uint[](path.length);

        recipients = new address[](path.length);
        recipients[path.length - 1] = to;

        for (uint i = path.length - 1; i > 0; i--) {
            uint ammIn = amm_calcInAmount(path[i - 1], path[i], amounts[i]);

            (uint dexIn, uint unfilledOut) = dex_calcInAmount(path[i - 1], path[i], amounts[i]);
            if(unfilledOut > 0) {
                uint ammUnfilledIn = amm_calcInAmount(path[i - 1], path[i], unfilledOut);
                unfilledAmounts[i - 1] = ammUnfilledIn;
                dexIn = dexIn.add(ammUnfilledIn);
            }
            
            if(ammIn == 0) {
                require(dexIn > 0 && unfilledOut == 0, "CowswapRouter: INSUFFICIENT_LIQUIDITY");
                amounts[i - 1] = dexIn;
                recipients[i - 1] = dex;
            } else {
                if(dexIn > 0 && dexIn < ammIn) {
                    amounts[i - 1] = dexIn;
                    recipients[i - 1] = dex;
                } else {
                    amounts[i - 1] = ammIn;
                    recipients[i - 1] = PancakeLibrary.pairFor(factory, path[i - 1], path[i]);
                }
            }
        }
    }

    function fastAddLiquidity(
        address tokenA, // A is payment token
        address tokenB,
        uint amountA, 
        address to,
        uint deadline
    ) external payable ensure(deadline) onlyCOWBHolder {
        require(amountA > 0, "A_AMOUNT_IS_ZERO");
        if(isETH(tokenA)) {
            require(msg.value == amountA, "FastAddLiquidity: IIA");
        } else {
            TransferHelper.safeTransferFrom(tokenA, msg.sender, address(this), amountA);
        }
        address pair = getPair(wrap(tokenA), wrap(tokenB));
        require(pair != address(0), "NO_PAIR");

        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = wrap(tokenB);

        uint amountBOut = exactInputInternal(amountA / 2, 0, path, address(this), address(this));

        (uint amountAOptimal,) = _addLiquidity(
            wrap(tokenA),
            wrap(tokenB),
            amountA / 2,
            amountBOut,
            0,
            0
        );
        require(amountAOptimal <= amountA / 2, "FastAddLiquidity: A_AMOUNT_EXCEEDS");

        _deposit(tokenA, address(this), pair, amountAOptimal);
        _deposit(isETH(tokenB) ? WETH : tokenB, address(this), pair, amountBOut);

        uint refund = amountA.sub(amountAOptimal.add(amountA / 2));
        if(refund > 0) {
            if(isETH(tokenA)) {
                TransferHelper.safeTransferETH(to, refund);
            } else {
                TransferHelper.safeTransfer(tokenA, to, refund);
            }
        }

        IPancakePair(pair).mint(to);
    }

    function fastRemoveLiquidity(
        address tokenA,  // A is final accepted token
        address tokenB,
        uint liquidity,
        address to,
        uint deadline
    ) public ensure(deadline) onlyCOWBHolder {
        (uint amountA, uint amountB) = removeLiquidity(wrap(tokenA), wrap(tokenB), liquidity, 0, 0, address(this), deadline);
        // swap B to A
        address[] memory path = new address[](2);
        path[0] = wrap(tokenB);
        path[1] = tokenA;

        exactInputInternal(amountB, 0, path, address(this), to);

        _withdraw(tokenA, to, amountA);
    }

    function fastRemoveLiquidityWithPermit(
        address tokenA, // A is final accepted token
        address tokenB,
        uint liquidity,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external onlyCOWBHolder {
        address pair = getPair(wrap(tokenA), wrap(tokenB));
        uint value = approveMax ? uint(-1) : liquidity;
        IPancakePair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        fastRemoveLiquidity(tokenA, tokenB, liquidity, to, deadline);
    }


    function dex_calcOutAmount(address tokenIn, address tokenOut, uint amountIn) public view returns(uint, uint) {
        return IStakeDex(dex).calcOutAmount(tokenIn, tokenOut, amountIn);
    }

    function dex_calcInAmount(address tokenIn, address tokenOut, uint amountOut) public view returns(uint, uint) {
        return IStakeDex(dex).calcInAmount(tokenIn, tokenOut, amountOut);
    }

    function amm_calcOutAmount(address tokenIn, address tokenOut, uint amountIn) public view returns(uint) {
        if(IPancakeFactory(factory).getPair(tokenIn, tokenOut) == address(0)) {
            return 0;
        }
        (uint reserveIn, uint reserveOut) = PancakeLibrary.getReserves(factory, tokenIn, tokenOut);
        if(reserveIn == 0 || reserveOut == 0) {
            return 0;
        }
        return PancakeLibrary.calcOutAmount(factory, tokenIn, tokenOut, amountIn);
    }

    function amm_calcInAmount(address tokenIn, address tokenOut, uint amountOut) public view returns(uint) {
        if(IPancakeFactory(factory).getPair(tokenIn, tokenOut) == address(0)) {
            return 0;
        }
        (uint reserveIn, uint reserveOut) = PancakeLibrary.getReserves(factory, tokenIn, tokenOut);
        if(reserveIn == 0 || reserveOut == 0) {
            return 0;
        }
        return PancakeLibrary.calcInAmount(factory, tokenIn, tokenOut, amountOut);
    }
}
