// SPDX-License-Identifier: MIT
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

// File: @openzeppelin/contracts/utils/Address.sol



pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol



pragma solidity ^0.6.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol



pragma solidity ^0.6.0;





/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// File: @openzeppelin/contracts/math/Math.sol



pragma solidity ^0.6.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// File: contracts/dex/StakeDex.sol


pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;





contract StakeDex {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    uint public pairId = 0;
    uint public AMP = 1e18;

    struct Liquidity {
        uint256 price;
        uint256 pending;
        uint256 filled;
        uint256 feeRewarded;
    }

    struct Depth {
        uint256 price;
        uint256 amount;
    }

    struct Rate {
        uint256 traded;
        uint256 fee;
    }

    Rate public HEAD = Rate({
        traded: uint256(-1),
        fee: 0
    });

    Rate public ZERO = Rate({
        traded: 0,
        fee: 0
    });

    // token0 => token1 => id
    mapping (address => mapping (address => uint)) public pairs;
    // id => decimal
    mapping (uint => int8) public decimals;
    // id => [ prices ]
    mapping (uint => uint256[]) public prices;
    // id => price => amount
    mapping (uint => mapping (uint => uint)) public depth;
    // id => price => rate
    mapping (uint => mapping (uint => Rate[])) public tradedRateStored;

    int8 public defaultDecimals = 8;

    address public feeTo;
    address public gov;

    uint public feeForTake = 20; // 0.2% 
    uint public feeForProvide = 12; // 0.10% to makers
    uint public feeForReserve = 8; // 0.10% reserved

    uint256 public amountInMin = 0; //500000;  // base is 10000
    uint256 public amountInMax = 10000000; // base is 10000



    // user => id => price => amount
    mapping (address => mapping (uint => mapping (uint => uint))) public userOrders;
    // user => id => price => rate
    mapping (address => mapping (uint => mapping (uint => uint))) public userRateRedeemed;


    // rewards
    IERC20 public rewardToken;

    // eg. USDT => BUSD -> 1e16(0.01) / BUSD => USDT -> 1e16(0.01)
    mapping (address => mapping (address => uint256)) public miningRate;
    
    uint256 public makerReservedRewards;



    event AddLiquidity(address indexed sender, address tokenIn, address tokenOut, uint price, uint amountIn, uint date);
    event RemoveLiquidity(address indexed sender, address tokenIn, address tokenOut, uint price, uint amountReturn, uint date);
    event Swap(address indexed sender, address tokenIn, address tokenOut, uint amountIn, uint amountOut, uint date);
    event Redeem(address indexed sender, address tokenIn, address tokenOut, uint price, uint filled, uint date);
    event CreatePair(address indexed token0, address indexed token1, uint date);

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }
    modifier onlyGov() { 
        require(gov == msg.sender, "Not gov");
        _; 
    }
    

    constructor(address feeTo_) public {
        gov = msg.sender;
        feeTo = feeTo_;
    }

    function updateDefaultDecimals(int8 decimals_) public onlyGov {
        defaultDecimals = decimals_;
    }

    function setRewardToken(address token_) public onlyGov {
        rewardToken = IERC20(token_);
    }


    function setFees(uint256 take_, uint256 provide_, uint256 reserve_) public onlyGov {
        require(take_ == provide_.add(reserve_), "take_ != provide_ + reserve_");
        feeForTake = take_;
        feeForProvide = provide_;
        feeForReserve = reserve_;
    }

    function setMiningRate(address tokenA, address tokenB, uint256 rate) public onlyGov {
        miningRate[tokenA][tokenB] = rate;
        miningRate[tokenB][tokenA] = rate;
    }

    function setAmountInLimit(uint256 min_, uint256 max_) public onlyGov {
        amountInMin = min_;
        amountInMax = max_;
    }
    
    function createPair(address tokenA, address tokenB) public {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        if(pairs[token0][token1] == 0) {
            pairId += 1;
            pairs[token0][token1] = pairId;
        }
        if(pairs[token1][token0] == 0) {
            pairId += 1;
            pairs[token1][token0] = pairId;
        }
        
        setPairDecimals(tokenA, tokenB, defaultDecimals);

        emit CreatePair(token0, token1, now);
    }

    function updatePairDecimals(address tokenA, address tokenB, int8 decimals_) public {
        require(gov == msg.sender, "Not gov");
        setPairDecimals(tokenA, tokenB, decimals_);
    }

    function setPairDecimals(address tokenA, address tokenB, int8 decimals_) internal {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        int8 dec01 = int8(decimals_) + int8(ERC20(token0).decimals()) - int8(ERC20(token1).decimals());
        int8 dec10 = int8(decimals_) + int8(ERC20(token1).decimals()) - int8(ERC20(token0).decimals());

        decimals[pairs[token0][token1]] = dec01;
        decimals[pairs[token1][token0]] = dec10;
    }


    function getPrices(address tokenIn, address tokenOut) public view returns(uint[] memory) {
        uint id = getPairId(tokenIn, tokenOut);
        return prices[id];
    }

    function getDepth(address tokenIn, address tokenOut) public view returns(Depth[] memory) {
        uint id = getPairId(tokenIn, tokenOut);
        Depth[] memory depths = new Depth[](prices[id].length);
        for(uint256 i = 0; i < prices[id].length; i++) {
            depths[i] = Depth({
                price: prices[id][i],
                amount: depth[id][prices[id][i]]
            });
        }
        return depths;
    }

    function getTradedRates(uint256 id, uint256 price) public view returns(Rate[] memory) {
        return tradedRateStored[id][price];
    }

    function getPairId(address tokenIn, address tokenOut) public view returns(uint) {
        return pairs[tokenIn][tokenOut];
    }


    function fetchPairId(address tokenIn, address tokenOut) public view returns(uint256) {
        uint id = getPairId(tokenIn, tokenOut);
        require(id > 0, "Not exists");
        return id;
    }

    function removeLiquidity(
        address tokenIn,
        address tokenOut,
        uint256 price
    ) public lock
    {
        uint id = fetchPairId(tokenIn, tokenOut);
        if(userOrders[msg.sender][id][price] > 0) {
            redeemTraded(msg.sender, tokenIn, tokenOut, price);    
        }

        uint amountOut = userOrders[msg.sender][id][price];
        require(amountOut > 0, "No Liquidity");

        if(depth[id][price] >= amountOut) {
            depth[id][price] = depth[id][price].sub(amountOut);
            userOrders[msg.sender][id][price] = 0;
        } else {
            // require(amountOut.sub(depth[id][price]) <= 100, "Insufficient Depth");
            amountOut = depth[id][price];
            depth[id][price] = 0;
            userOrders[msg.sender][id][price] = 0;
        }

        uint amountReturn = getAmountOut(id, amountOut, price);
        if(amountReturn > 0) {
            IERC20(tokenIn).transfer(msg.sender, amountReturn);    
        }

        emit RemoveLiquidity(msg.sender, tokenIn, tokenOut, price, amountReturn, now);

        // if(depth[id][price] == 0) {
        //     skimPriceArray(tokenIn, tokenOut);
        // }
    }

    function calcAmountInLimit(address token) public view returns(uint256 min, uint256 max) {
        uint256 dec = uint256(ERC20(token).decimals());
        min = amountInMin.mul(10 ** dec).div(10000);
        max = amountInMax.mul(10 ** dec).div(10000);
    }

    function addLiquidity(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    ) public lock
    {   
        require(amountIn > 0 && amountOut > 0, "ZERO");
        (uint256 min, uint256 max) = calcAmountInLimit(tokenIn);
        require(amountIn >= min && amountIn <= max,  "Exceeds Limit");

        if(getPairId(tokenIn, tokenOut) == 0) {
            createPair(tokenIn, tokenOut);
        }

        uint id = fetchPairId(tokenIn, tokenOut);

        int8 exp = decimals[id];

        uint256 price;

        if(exp > 0) {
            price = amountOut.mul(10 ** uint(exp)).div(amountIn);
            amountOut = price.mul(amountIn).div(10 ** uint(exp));
        } else {
            price = amountOut.div(10 ** uint(-exp)).div(amountIn);
            amountOut = price.mul(amountIn).mul(10 ** uint(-exp));
        }

        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);

        if(userOrders[msg.sender][id][price] > 0) {
            redeemTraded(msg.sender, tokenIn, tokenOut, price);
        }

        depth[id][price] = depth[id][price].add(amountOut);
        userOrders[msg.sender][id][price] = userOrders[msg.sender][id][price].add(amountOut);

        addToPriceArray(tokenIn, tokenOut, price);

        if (tradedRateStored[id][price].length == 0) {
            tradedRateStored[id][price].push(HEAD);
        }
        uint256 size = tradedRateStored[id][price].length;
        if(tradedRateStored[id][price][size - 1].traded == 0) {
            userRateRedeemed[msg.sender][id][price] = size - 1;
        } else {
            tradedRateStored[id][price].push(ZERO);
            userRateRedeemed[msg.sender][id][price] = size;
        }

        emit AddLiquidity(msg.sender, tokenIn, tokenOut, price, amountIn, now);
    }

    function addToPriceArray(address tokenIn, address tokenOut, uint256 price) internal {
        uint id = getPairId(tokenIn, tokenOut);
        uint256[] storage priceArray = prices[id];

        if(priceArray.length == 0) {
            priceArray.push(price);
            return;
        }
        // priceArray.push();
        uint256 i = 0;
        uint256 len = priceArray.length;
        bool pushed = false;
        while(i < len) {
            if(priceArray[i] > price) {
                priceArray.push();
                for(uint256 j = len; j > i; j--) {
                    priceArray[j] = priceArray[j - 1];
                }
                priceArray[i] = price;
                pushed = true;
                break;
            } else if (price == priceArray[i]) {
                pushed = true;
                break;
            } else {
                i = i + 1;
            }
        }

        if(!pushed) {
            priceArray.push(price);
            // priceArray[len - 1] = price;
        }
    }

    function skimPriceArray(
        address tokenIn, 
        address tokenOut
    ) internal 
    {
        uint id = getPairId(tokenIn, tokenOut);
        uint256[] storage priceArray = prices[id];

        if(priceArray.length == 0) {
            return;
        }

        if(priceArray.length == 1) {
            if(depth[id][priceArray[0]] == 0) {
                priceArray.pop();
            }
            return;
        }

        uint256 i = 0;
        uint256 len = priceArray.length;

        while(i < len) {
            uint256 price = priceArray[i];
            if(depth[id][price] == 0) {
                for(uint256 j = i; j < len - 1; j++) {
                    priceArray[j] = priceArray[j + 1];
                }
                priceArray.pop();
                len = len - 1;
            }
            i++;
        }
    }
    function calcRate(uint256 currentRate, uint256 storedRate) public view returns(uint256) {
        return uint(AMP).sub(storedRate).mul(currentRate).div(AMP);
    }


    function redeemTraded(
        address account, 
        address tokenIn, 
        address tokenOut, 
        uint256 price
    ) internal returns(uint256 pending, uint256 filled) 
    {
        uint id = fetchPairId(tokenIn, tokenOut);
        pending = userOrders[account][id][price];

        require(pending > 0, "No Liquidity");

        Rate[] storage rates = tradedRateStored[id][price];

        uint256 accumlatedRate = 0;
        uint256 accumlatedRateFee = 0;
        uint256 startIndex = userRateRedeemed[account][id][price];


        for(uint256 i = startIndex; i < rates.length; i++) {
            accumlatedRateFee += calcRate(rates[i].fee, i == startIndex ? 0 : rates[i - 1].traded);
            accumlatedRate += calcRate(rates[i].traded, i == startIndex ? 0 : rates[i - 1].traded);
            if(rates[i].traded == AMP) {
                break;    
            }
        }
        filled = pending.mul(accumlatedRate).div(AMP);
        // uint256 fee = pending.mul(accumlatedRateFee).div(AMP);
        if(filled > 0) {
            IERC20(tokenOut).transfer(account, filled.add(pending.mul(accumlatedRateFee).div(AMP)));
            userOrders[account][id][price] = pending.sub(filled);
            emit Redeem(account, tokenIn, tokenOut, price, filled, now);
        }
    }

    function getLiquidity(
        address account, 
        address tokenIn, 
        address tokenOut, 
        uint256 price
    ) public view returns(uint256 feeRewarded, uint256 filled, uint256 pending) {
        uint id = fetchPairId(tokenIn, tokenOut);
        pending = userOrders[account][id][price];

        if(pending == 0) {
            return (0, 0, 0);
        }

        Rate[] memory rates = tradedRateStored[id][price];

        uint256 accumlatedRate = 0;
        uint256 accumlatedRateFee = 0;
        uint256 startIndex = userRateRedeemed[account][id][price];

        for(uint256 i = startIndex; i < rates.length; i++) {
            accumlatedRateFee += calcRate(rates[i].fee, i == startIndex ? 0 : rates[i - 1].traded);
            accumlatedRate += calcRate(rates[i].traded, i == startIndex ? 0 : rates[i - 1].traded);
            if(rates[i].traded == AMP) {
                break;
            }
        }
        filled = pending.mul(accumlatedRate).div(AMP);
        feeRewarded = pending.mul(accumlatedRateFee).div(AMP);
        pending = pending.sub(filled);
    }

    function getAllLiquidities(
        address account, 
        address tokenIn, 
        address tokenOut
    ) public view returns(Liquidity[] memory) {
        uint id = getPairId(tokenIn, tokenOut);
        Liquidity[] memory liquids = new Liquidity[](prices[id].length);
        for(uint256 i = 0; i < prices[id].length; i++) {
            (uint256 feeRewarded, uint256 filled, uint256 pending) = getLiquidity(account, tokenIn, tokenOut, prices[id][i]);
            if(feeRewarded == 0 && filled == 0 && pending == 0) {
                continue;
            }
            liquids[i] = Liquidity({
                price: prices[id][i],
                pending: pending,
                filled: filled,
                feeRewarded: feeRewarded
            });
        }
        return liquids;
    }


    function redeem(address tokenIn, address tokenOut, uint256 price) public lock {
        uint id = fetchPairId(tokenIn, tokenOut);
        redeemTraded(msg.sender, tokenIn, tokenOut, price);


        uint256 size = tradedRateStored[id][price].length;

        if(tradedRateStored[id][price][size - 1].traded == 0) {
            userRateRedeemed[msg.sender][id][price] = size - 1;
        } else {
            tradedRateStored[id][price].push(ZERO);
            userRateRedeemed[msg.sender][id][price] = size;
        }
    }

    function swap(
        address tokenIn, 
        address tokenOut, 
        uint amountIn, 
        uint amountOutMin
    ) public returns(uint256 amountOut)
    {   
        uint id = fetchPairId(tokenOut, tokenIn);
        uint total = amountIn;
        uint totalFee = 0;

        for(uint256 i = 0; i < prices[id].length; i++) {
            uint256 p = prices[id][i];
            if(depth[id][p] == 0) {
                continue;
            }
            (uint _amountReturn, uint _amountOut, uint _reserveFee, uint _pending) = _swapWithFixedPrice(id, depth[id][p], amountIn, p);

            totalFee = totalFee.add(_reserveFee);
            amountOut = amountOut.add(_amountOut);
            amountIn = _amountReturn;
            depth[id][p] = _pending;

            if(amountIn == 0) {
                break;
            }
        }
        require(amountOut >= amountOutMin && amountOut > 0, "INSUFFICIENT_OUT_AMOUNT");

        IERC20(tokenIn).transferFrom(msg.sender, address(this), total.sub(amountIn));
        IERC20(tokenIn).transfer(feeTo, totalFee);
        IERC20(tokenOut).transfer(msg.sender, amountOut);

        emit Swap(msg.sender, tokenIn, tokenOut, amountIn, amountOut, now);
    }


    function _swapWithFixedPrice(
        uint id,
        uint amountPending,
        uint amountIn, 
        uint price
    ) internal returns(uint /*amountReturn*/, uint amountOut, uint reserveFee, uint /*pending*/) {

        uint takeFee = amountPending.mul(feeForTake).div(10000);
        uint256 rateTrade;
        uint256 rateFee;
        
        if(amountIn >= amountPending.add(takeFee)) {
            reserveFee = amountPending.mul(feeForReserve).div(10000);

            rateTrade = AMP;
            rateFee = takeFee.sub(reserveFee).mul(AMP).div(amountPending);

            amountOut += getAmountOut(id, amountPending, price);

            amountIn = amountIn.sub(amountPending).sub(takeFee);
            amountPending = 0;
        } else {
            takeFee = amountIn.mul(feeForTake).div(10000);
            reserveFee = amountIn.mul(feeForReserve).div(10000);

            rateTrade = amountIn.sub(takeFee).mul(AMP).div(amountPending);
            rateFee = takeFee.sub(reserveFee).mul(AMP).div(amountPending);


            amountOut += getAmountOut(id, amountIn.sub(takeFee), price);

            amountPending = amountPending.sub(amountIn.sub(takeFee));
            amountIn = 0;
        }

        Rate storage rate = tradedRateStored[id][price][tradedRateStored[id][price].length - 1];

        rate.fee += calcRate(rateFee, rate.traded);
        rate.traded += calcRate(rateTrade, rate.traded);

        return (amountIn, amountOut, reserveFee, amountPending);
    }

    

    function getAmountOut(uint256 id, uint256 amountIn, uint256 price) public view returns(uint256) {
        int8 exp = decimals[id];
        if(exp > 0) {
            return amountIn.mul(10 ** uint(exp)).div(price);
        } else {
            return amountIn.div(10 ** uint(-exp)).div(price);
        }
    }

    function getAmountIn(uint256 id, uint256 amountOut, uint256 price) public view returns(uint256) {
        int8 exp = decimals[id];
        if(exp > 0) {
            return amountOut.mul(price).div(10 ** uint(exp));
        } else {
            return amountOut.mul(price).mul(10 ** uint(-exp));
        }
    }

    function calcInAmount(
        address tokenIn, 
        address tokenOut, 
        uint amountOut
    ) public view returns(uint256 amountIn, uint256 amountReturn) {
        uint id = fetchPairId(tokenOut, tokenIn);

        for(uint256 i = 0; i < prices[id].length; i++) {
            uint256 p = prices[id][i];
            if(depth[id][p] == 0) {
                continue;
            }

            uint256 amountWithFee = getAmountIn(id, amountOut, p).mul(10000 + feeForTake).div(10000);

            if(amountWithFee > depth[id][p]) {
                amountIn += depth[id][p].mul(10000 + feeForTake).div(10000);
                amountOut = amountOut.sub(getAmountOut(id, depth[id][p], p));
            } else {
                amountIn += getAmountIn(id, amountOut, p).mul(10000 + feeForTake).div(10000);
                amountOut = 0;
            }
        }
        amountReturn = amountOut;
    }

    function calcOutAmount(
        address tokenIn, 
        address tokenOut, 
        uint amountIn
    ) public view returns(uint256 amountOut, uint256 amountReturn) 
    {
        uint id = fetchPairId(tokenOut, tokenIn);

        for(uint256 i = 0; i < prices[id].length; i++) {
            uint256 p = prices[id][i];
            if(depth[id][p] == 0) {
                continue;
            }

            uint256 amountWithFee = depth[id][p].add(depth[id][p].mul(feeForTake).div(10000));

            if(amountIn >= amountWithFee) {
                // amountOut += depth[id][p].mul(1e18).div(p);
                amountOut += getAmountOut(id, depth[id][p], p);
                amountIn = amountIn.sub(amountWithFee);
            } else {
                uint256 fee = amountIn.mul(feeForTake).div(10000);
                // amountOut += amountIn.sub(fee).mul(1e18).div(p);
                amountOut += getAmountOut(id, amountIn.sub(fee), p);
                amountIn = 0;
                break;
            }
        }

        amountReturn = amountIn;
    }
}
