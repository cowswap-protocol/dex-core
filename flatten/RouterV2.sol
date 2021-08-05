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

// File: @openzeppelin/contracts/introspection/IERC165.sol



pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol



pragma solidity ^0.6.2;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Metadata.sol



pragma solidity ^0.6.2;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol



pragma solidity ^0.6.2;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol



pragma solidity ^0.6.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
    external returns (bytes4);
}

// File: @openzeppelin/contracts/introspection/ERC165.sol



pragma solidity ^0.6.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
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

// File: @openzeppelin/contracts/utils/EnumerableSet.sol



pragma solidity ^0.6.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// File: @openzeppelin/contracts/utils/EnumerableMap.sol



pragma solidity ^0.6.0;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        return _get(map, key, "EnumerableMap: nonexistent key");
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint256(value)));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key), errorMessage)));
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol



pragma solidity ^0.6.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol



pragma solidity ^0.6.0;












/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        // If there is no base URI, return the token URI.
        if (bytes(_baseURI).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(_baseURI, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(_baseURI, tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
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

// File: contracts/core/StakeDex.sol


pragma solidity ^0.6.12;





contract StakeDex is ERC721 {
    using SafeMath for uint256;

    uint public AMP = 1e18;

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


    struct Pair {
        uint256 id;
        int8 decimals;
        uint256[] prices;
        // price => amount
        mapping (uint256 => uint256) depth;
        // price => Rate[]
        mapping (uint256 => Rate[]) tradedRateStored;

        address tokenIn;
        address tokenOut;
    }

    mapping (uint256 => Pair) public getPair;
    mapping (address => mapping (address => uint)) public getPairId;
    
    int8 public defaultDecimals = 10;

    address public feeTo;
    address public gov;

    uint public feeForTake = 20; // 0.2% 
    uint public feeForProvide = 10; // 0.10% to makers
    uint public feeForReserve = 10; // 0.10% reserved

    mapping (address => uint256) public reserves;

    struct Position {
        // the nonce for permits
        uint96 nonce;
        // the address that is approved for spending this token
        address operator;
        uint256 pairId;

        // uint256 amountIn;
        uint256 price;
        uint256 pendingOut;
        uint256 rateRedeemedIndex;
    }

    uint256 private _nextId = 1;

    mapping (uint256 => Position) private _positions;
    
    

    event IncreasePosition(address indexed sender, address tokenIn, address tokenOut, uint price, uint amountIn);
    event DecreasePosition(address indexed sender, address tokenIn, address tokenOut, uint price, uint amountIn);

    event Swap(address indexed sender, address tokenIn, address tokenOut, uint amountIn, uint amountOut);
    event Redeem(address indexed sender, address tokenIn, address tokenOut, uint price, uint filled);
    event CreatePair(address indexed token0, address indexed token1, uint256 id);

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

    modifier isAuthorizedForToken(uint256 tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), 'Not approved');
        _;
    }
    

    constructor(address feeTo_) public ERC721('Cowswap Positions', 'COW-POS') {
        gov = msg.sender;
        feeTo = feeTo_;
    }

    function setFees(uint256 take_, uint256 provide_, uint256 reserve_) public onlyGov {
        require(take_ == provide_.add(reserve_), "take_ != provide_ + reserve_");
        feeForTake = take_;
        feeForProvide = provide_;
        feeForReserve = reserve_;
    }

    function createPair(address tokenIn, address tokenOut) public {
        getPairId[tokenIn][tokenOut] += 1;

        uint256 id = getPairId[tokenIn][tokenOut];

        int8 decimals = int8(defaultDecimals) + int8(IERC20(tokenIn).decimals()) - int8(IERC20(tokenOut).decimals());

        Pair storage pair = getPair[id];
        pair.id = id;
        pair.decimals = decimals;
        pair.tokenIn = tokenIn;
        pair.tokenOut = tokenOut;

        emit CreatePair(tokenIn, tokenOut, id);
    }

    function updatePairDecimals(address tokenIn, address tokenOut, int8 decimals_) public {
        require(gov == msg.sender, "Not gov");
        getPair[getPairId[tokenIn][tokenOut]].decimals = int8(decimals_) + int8(IERC20(tokenIn).decimals()) - int8(IERC20(tokenOut).decimals());
    }

    function _updateReserve(address token) internal {
        reserves[token] = IERC20(token).balanceOf(address(this));
    }

    function _deposit(address token, address from, uint256 amount) internal returns(uint256) {
        uint256 beforeBalance = IERC20(token).balanceOf(address(this));
        IERC20(token).transferFrom(from, address(this), amount);
        uint256 afterBalance = IERC20(token).balanceOf(address(this));
        return afterBalance.sub(beforeBalance);
    }

    function _withdraw(address token, address to, uint256 amount) internal {
        require(IERC20(token).balanceOf(address(this)) >= amount, "Insufficient balance");
        IERC20(token).transfer(to, amount);
    }

    function _recordRateIndex(uint256 id, uint256 price) internal returns(uint256 rateIndex) {
        Pair storage pair = getPair[id];
        uint256 size = pair.tradedRateStored[price].length;
        if(pair.tradedRateStored[price][size - 1].traded == 0) {
            // position.rateRedeemedIndex = size - 1;
            rateIndex = size - 1;
        } else {
            pair.tradedRateStored[price].push(ZERO);
            // position.rateRedeemedIndex = size;
            rateIndex = size;
        }
    }

    
    function mint(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    ) external lock returns(uint256 tokenId)
    {   
        require(amountIn > 0 && amountOut > 0, "ZERO");

        if(getPairId[tokenIn][tokenOut] == 0) {
            createPair(tokenIn, tokenOut);
        }
        uint256 id = getPairId[tokenIn][tokenOut];
        Pair storage pair = getPair[id];

        amountIn = _deposit(tokenIn, msg.sender, amountIn);

        uint256 price;

        if(pair.decimals > 0) {
            price = amountOut.mul(10 ** uint(pair.decimals)).div(amountIn);
            amountOut = price.mul(amountIn).div(10 ** uint(pair.decimals));
        } else {
            price = amountOut.div(10 ** uint(-pair.decimals)).div(amountIn);
            amountOut = price.mul(amountIn).mul(10 ** uint(-pair.decimals));
        }

        require(price > 0, "Zero Price");

        pair.depth[price] = pair.depth[price].add(amountOut); 

        addToPriceArray(tokenIn, tokenOut, price);

        if(pair.tradedRateStored[price].length == 0) {
            pair.tradedRateStored[price].push(HEAD);
        }

        _updateReserve(tokenIn);

        _mint(msg.sender, (tokenId = _nextId++));

        Position storage position = _positions[tokenId];
        position.pairId = id;
        position.price = price;
        position.pendingOut = amountOut;
        position.rateRedeemedIndex = _recordRateIndex(position.pairId, position.price);

        emit IncreasePosition(msg.sender, tokenIn, tokenOut, price, amountIn);
    }

    function increasePosition(uint256 tokenId, uint256 amountIn) external lock {
        _redeemTraded(tokenId);
        Position storage position = _positions[tokenId];
        Pair storage pair = getPair[position.pairId];
        amountIn = _deposit(pair.tokenIn, msg.sender, amountIn);
        uint256 amountOut = getAmountIn(position.pairId, amountIn, position.price);
        pair.depth[position.price] = pair.depth[position.price].add(amountOut);

        position.pendingOut = position.pendingOut.add(amountOut);
        position.rateRedeemedIndex = _recordRateIndex(position.pairId, position.price);
        _updateReserve(pair.tokenIn);

        emit IncreasePosition(msg.sender, pair.tokenIn, pair.tokenOut, position.price, amountIn);
    }


    function decreasePosition(uint256 tokenId, uint256 amountIn) external lock isAuthorizedForToken(tokenId) {
        _redeemTraded(tokenId);
        Position storage position = _positions[tokenId];
        Pair storage pair = getPair[position.pairId];
        uint256 amountOut = getAmountIn(position.pairId, amountIn, position.price);
        require(position.pendingOut >= amountOut, "Insufficient position");
        pair.depth[position.price] = pair.depth[position.price].sub(amountOut);

        position.pendingOut = position.pendingOut.sub(amountOut);
        position.rateRedeemedIndex = _recordRateIndex(position.pairId, position.price);
        _withdraw(pair.tokenIn, ownerOf(tokenId), amountIn);
        _updateReserve(pair.tokenIn);

        emit DecreasePosition(msg.sender, pair.tokenIn, pair.tokenOut, position.price, amountIn);
    }

    function burn(uint256 tokenId) external lock isAuthorizedForToken(tokenId) {
        address owner = ownerOf(tokenId);
        Position storage position = _positions[tokenId];
        Pair storage pair = getPair[position.pairId];
        _redeemTraded(tokenId);
        uint amountIn = getAmountOut(position.pairId, position.pendingOut, position.price);
        if(amountIn > 0) {
            _withdraw(pair.tokenIn, owner, amountIn);
        }
        // redeem
        _burn(tokenId);
        delete _positions[tokenId];

        emit DecreasePosition(msg.sender, pair.tokenIn, pair.tokenOut, position.price, amountIn);
    }

    function _redeemTraded(uint256 tokenId) internal {
        Position storage position = _positions[tokenId];
        Pair storage pair = getPair[position.pairId];

        address owner = ownerOf(tokenId);

        require(position.pendingOut > 0, "No Liquidity");

        Rate[] storage rates = pair.tradedRateStored[position.price];

        uint256 accumlatedRate = 0;
        uint256 accumlatedRateFee = 0;
        uint256 startIndex = position.rateRedeemedIndex;


        for(uint256 i = startIndex; i < rates.length; i++) {
            accumlatedRateFee += calcRate(rates[i].fee, i == startIndex ? 0 : rates[i - 1].traded);
            accumlatedRate += calcRate(rates[i].traded, i == startIndex ? 0 : rates[i - 1].traded);
            if(rates[i].traded == AMP) {
                break;
            }
        }
        uint256 filled = position.pendingOut.mul(accumlatedRate).div(AMP);
        uint256 fee = position.pendingOut.mul(accumlatedRateFee).div(AMP);
        if(filled > 0) {
            _withdraw(pair.tokenOut, owner, filled.add(fee));
            position.pendingOut = position.pendingOut.sub(filled);

            _updateReserve(pair.tokenOut);

            emit Redeem(owner, pair.tokenIn, pair.tokenOut, position.price, filled);
        }
    }

    function redeem(uint256 tokenId) external lock isAuthorizedForToken(tokenId) {
        Position storage position = _positions[tokenId];
        _redeemTraded(tokenId);
        position.rateRedeemedIndex = _recordRateIndex(position.pairId, position.price);
    }


    function addToPriceArray(address tokenIn, address tokenOut, uint256 price) internal {
        uint id = getPairId[tokenIn][tokenOut];
        uint256[] storage priceArray = getPair[id].prices;

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

    // function skimPriceArray(
    //     address tokenIn, 
    //     address tokenOut
    // ) internal 
    // {
    //     uint id = getPairId[tokenIn][tokenOut];
    //     Pair storage pair = getPair[id];
    //     uint256[] storage priceArray = pair.prices;

    //     if(priceArray.length == 0) {
    //         return;
    //     }

    //     if(priceArray.length == 1) {
    //         if(pair.depth[priceArray[0]] == 0) {
    //             priceArray.pop();
    //         }
    //         return;
    //     }

    //     uint256 i = 0;
    //     uint256 len = priceArray.length;

    //     while(i < len) {
    //         uint256 price = priceArray[i];
    //         if(pair.depth[price] == 0) {
    //             for(uint256 j = i; j < len - 1; j++) {
    //                 priceArray[j] = priceArray[j + 1];
    //             }
    //             priceArray.pop();
    //             len = len - 1;
    //         }
    //         i++;
    //     }
    // }

    function calcRate(uint256 currentRate, uint256 storedRate) public view returns(uint256) {
        return uint(AMP).sub(storedRate).mul(currentRate).div(AMP);
    }

    function swap(
        address tokenIn, 
        address tokenOut, 
        uint amountOutMin,
        address to
    ) external returns(uint256 amountOut)
    {   
        uint id = getPairId[tokenOut][tokenIn];

        Pair storage pair = getPair[id];

        uint256 amountIn = IERC20(tokenIn).balanceOf(address(this)).sub(reserves[tokenIn]);

        uint total = amountIn;
        uint totalFee = 0;

        for(uint256 i = 0; i < pair.prices.length; i++) {
            uint256 p = pair.prices[i];

            if(pair.depth[p] == 0) {
                continue;
            }
            (uint _amountReturn, uint _amountOut, uint _reserveFee) = _swapWithFixedPrice(id, amountIn, p);

            totalFee = totalFee.add(_reserveFee);
            amountOut = amountOut.add(_amountOut);
            amountIn = _amountReturn;

            if(amountIn == 0) {
                break;
            }
        }
        require(amountOut >= amountOutMin && amountOut > 0, "INSUFFICIENT_OUT_AMOUNT");

        if(amountIn > 0) {
            IERC20(tokenIn).transfer(msg.sender, amountIn); // refund
        }

        // IERC20(tokenIn).transferFrom(msg.sender, address(this), total.sub(amountIn));
        IERC20(tokenIn).transfer(feeTo, totalFee);
        // IERC20(tokenOut).transfer(msg.sender, amountOut);
        if(to != address(this)) {
            IERC20(tokenOut).transfer(to, amountOut);
        }

        reserves[tokenOut] = reserves[tokenOut].sub(amountOut);
        _updateReserve(tokenIn);

        emit Swap(msg.sender, tokenIn, tokenOut, total.sub(amountIn), amountOut);
    }


    function _swapWithFixedPrice(
        uint id,
        uint amountIn, 
        uint price
    ) internal returns(uint /*amountReturn*/, uint amountOut, uint reserveFee) {
        Pair storage pair = getPair[id];

        uint takeFee = pair.depth[price].mul(feeForTake).div(10000);
        uint256 rateTrade;
        uint256 rateFee;
        
        if(amountIn >= pair.depth[price].add(takeFee)) {
            reserveFee = pair.depth[price].mul(feeForReserve).div(10000);

            rateTrade = AMP;
            rateFee = takeFee.sub(reserveFee).mul(AMP).div(pair.depth[price]);

            amountOut += getAmountOut(id, pair.depth[price], price);

            amountIn = amountIn.sub(pair.depth[price]).sub(takeFee);
            pair.depth[price] = 0;
        } else {
            takeFee = amountIn.mul(feeForTake).div(10000);
            reserveFee = amountIn.mul(feeForReserve).div(10000);

            rateTrade = amountIn.sub(takeFee).mul(AMP).div(pair.depth[price]);
            rateFee = takeFee.sub(reserveFee).mul(AMP).div(pair.depth[price]);

            amountOut += getAmountOut(id, amountIn.sub(takeFee), price);

            pair.depth[price] = pair.depth[price].sub(amountIn.sub(takeFee));
            amountIn = 0;
        }

        Rate storage rate = pair.tradedRateStored[price][pair.tradedRateStored[price].length - 1];

        rate.fee += calcRate(rateFee, rate.traded);
        rate.traded += calcRate(rateTrade, rate.traded);

        return (amountIn, amountOut, reserveFee);
    }

    function getAmountOut(uint256 id, uint256 amountIn, uint256 price) public view returns(uint256) {
        int8 exp = getPair[id].decimals;
        if(exp > 0) {
            return amountIn.mul(10 ** uint(exp)).div(price);
        } else {
            return amountIn.div(10 ** uint(-exp)).div(price);
        }
    }

    function getAmountIn(uint256 id, uint256 amountOut, uint256 price) public view returns(uint256) {
        int8 exp = getPair[id].decimals;
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
        uint id = getPairId[tokenOut][tokenIn];
        
        for(uint256 i = 0; i < getPair[id].prices.length; i++) {
            uint256 p = getPair[id].prices[i];
            if(getPair[id].depth[p] == 0) {
                continue;
            }

            uint256 amountWithFee = getAmountIn(id, amountOut, p).mul(10000 + feeForTake).div(10000);

            if(amountWithFee > getPair[id].depth[p]) {
                amountIn += getPair[id].depth[p].add(getPair[id].depth[p].mul(feeForTake).div(10000));
                amountOut = amountOut.sub(getAmountOut(id, getPair[id].depth[p], p));
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
        uint id = getPairId[tokenOut][tokenIn];

        for(uint256 i = 0; i < getPair[id].prices.length; i++) {
            uint256 p = getPair[id].prices[i];
            if(getPair[id].depth[p] == 0) {
                continue;
            }

            uint256 amountWithFee = getPair[id].depth[p].add(getPair[id].depth[p].mul(feeForTake).div(10000));

            if(amountIn >= amountWithFee) {
                amountOut += getAmountOut(id, getPair[id].depth[p], p);
                amountIn = amountIn.sub(amountWithFee);
            } else {
                uint256 fee = amountIn.mul(feeForTake).div(10000);
                amountOut += getAmountOut(id, amountIn.sub(fee), p);
                amountIn = 0;
                break;
            }
        }

        amountReturn = amountIn;
    }

    function positions(uint256 tokenId) 
        external 
        view 
        returns(
            uint256 nonce,
            address operator,
            uint256 pairId,
            uint256 pendingIn,
            uint256 price,
            uint256 pendingOut,
            uint256 rateRedeemedIndex,
            address tokenIn,
            address tokenOut,
            uint256 filled,
            uint256 feeRewarded
        ) 
    {
        require(_exists(tokenId), "No position");
        Position memory position = _positions[tokenId];
        Pair storage pair = getPair[position.pairId];

        if(position.pendingOut == 0) {
            filled = 0;
            feeRewarded = 0;
            pendingOut = 0;
        } else {
            Rate[] storage rates = pair.tradedRateStored[position.price];

            uint256 accumlatedRate = 0;
            uint256 accumlatedRateFee = 0;
            uint256 startIndex = position.rateRedeemedIndex;
            for(uint256 i = startIndex; i < rates.length; i++) {
                accumlatedRateFee += calcRate(rates[i].fee, i == startIndex ? 0 : rates[i - 1].traded);
                accumlatedRate += calcRate(rates[i].traded, i == startIndex ? 0 : rates[i - 1].traded);
                if(rates[i].traded == AMP) {
                    break;
                }
            }
            filled = position.pendingOut.mul(accumlatedRate).div(AMP);
            feeRewarded = position.pendingOut.mul(accumlatedRateFee).div(AMP);
            pendingOut = position.pendingOut.sub(filled);
        }

        pendingIn = getAmountOut(position.pairId, pendingOut, position.price);

        return (
            position.nonce,
            position.operator,
            position.pairId,
            pendingIn,
            position.price,
            pendingOut,
            position.rateRedeemedIndex,
            pair.tokenIn,
            pair.tokenOut,
            filled,
            feeRewarded
        );
    }


    function pairs(address tokenIn, address tokenOut) 
    public 
    view 
    returns(
        uint256 id,
        int8 decimals,
        uint256[] memory prices,
        uint256[] memory depths
    ) {
        id = getPairId[tokenIn][tokenOut];
        Pair storage pair = getPair[id];
        decimals = pair.decimals;
        prices = pair.prices;
        depths = new uint256[](prices.length);
        for(uint256 i = 0; i < prices.length; i++) {
            depths[i] = pair.depth[prices[i]];
        }
    }
}

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

// File: contracts/interfaces/IWETH.sol


pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
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
                // hex'00fb7f630766e6a796048ea87d01acd3068e8ff67d078148a3fa3f4a84f69bd5' // init code hash
                hex'2e80a862c33dde690d1e8a5316265736511efd1592c4c05b10d8d3e5eac5f158' // init code hash
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

// File: contracts/core/RouterV2.sol


pragma solidity ^0.6.12;


// import "../interfaces/IPancakePair.sol";





interface IProofOfTrade {
    function validCOWBHolder(address user) external view returns(bool);
    function record(address user, address token, uint256 amount) external;
}

contract RouterV2 {
    using SafeMath for uint256;

    address public dex; 
    address public factory;
    address public WETH;

    // IProofOfTrade public pot;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'EXPIRED');
        _;
    }

    constructor(address _dex, address _factory, address _WETH/*, address _pot*/) public {
        dex = _dex;
        factory = _factory;
        WETH = _WETH;
        // pot = IProofOfTrade(_pot);
    }

    receive() external payable {
        // assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
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
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = PancakeLibrary.pairFor(factory, tokenA, tokenB);

        if(tokenA == WETH) {
            IWETH(WETH).deposit{value: amountA}();
            assert(IWETH(WETH).transfer(pair, amountA));
            if(msg.value > amountA) {
                TransferHelper.safeTransferETH(msg.sender, msg.value - amountA);
            }
            TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        } else if(tokenB == WETH) {
            IWETH(WETH).deposit{value: amountB}();
            assert(IWETH(WETH).transfer(pair, amountB));
            if(msg.value > amountB) {
                TransferHelper.safeTransferETH(msg.sender, msg.value - amountB);
            }
            TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        } else {
            TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
            TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        }

        liquidity = IPancakePair(pair).mint(to);
    }


    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool receiveETH
    ) public ensure(deadline) returns (uint amountA, uint amountB) {
        receiveETH = receiveETH && (tokenA == WETH || tokenB == WETH);
        address pair = PancakeLibrary.pairFor(factory, tokenA, tokenB);
        IPancakePair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = IPancakePair(pair).burn(receiveETH ? address(this) : to);
        (address token0,) = PancakeLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'CowswapRouter: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'CowswapRouter: INSUFFICIENT_B_AMOUNT');
        if(receiveETH) {
            if(tokenA == WETH) {
                IWETH(WETH).withdraw(amountA);
                TransferHelper.safeTransferETH(to, amountA);
                TransferHelper.safeTransfer(tokenB, to, amountB);
            } else if(tokenB == WETH) {
                IWETH(WETH).withdraw(amountB);
                TransferHelper.safeTransferETH(to, amountB);
                TransferHelper.safeTransfer(tokenA, to, amountA);
            }
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
        bool receiveETH,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB) {
        IPancakePair(PancakeLibrary.pairFor(factory, tokenA, tokenB)).permit(msg.sender, address(this), approveMax ? uint(-1) : liquidity, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline, receiveETH);
    }


    function exactInput(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        bool receiveETH
    ) external payable ensure(deadline) returns (uint[] memory amounts) {
        address[] memory recipients;
        (amounts, recipients) = getAmountsOut(amountIn, path, to);

        if(msg.value == amountIn && path[0] == WETH) {
            IWETH(WETH).deposit{value: amountIn}();
            assert(IWETH(WETH).transfer(recipients[0], amountIn));
        } else {
            IERC20(path[0]).transferFrom(msg.sender, recipients[0], amounts[0]);
        }
        
        require(amounts[path.length - 1] >= amountOutMin, "CowswapRouter: INSUFFICIENT_OUTPUT_AMOUNT");

        receiveETH = receiveETH && path[path.length - 1] == WETH;
        if(receiveETH) {
            recipients[recipients.length - 1] = address(this);
        }

        for(uint i; i < path.length - 1; i++) {
            if(recipients[i] == dex) {
                StakeDex(dex).swap(path[i], path[i + 1], 0, recipients[i + 1]);
            } else {
                (address input, address output) = (path[i], path[i + 1]);
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
                pair.swap(amount0Out, amount1Out, recipients[i + 1], new bytes(0));
            }
        }

        if(receiveETH) {
            uint amountOut = IERC20(WETH).balanceOf(address(this));
            require(amountOut >= amountOutMin, 'CowswapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
            IWETH(WETH).withdraw(amountOut);
            TransferHelper.safeTransferETH(to, amountOut);
        }

        // pot.record(msg.sender, path[path.length - 1], amounts[amounts.length - 1]);
    }

    function exactOutput(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline,
        bool receiveETH
    ) external payable ensure(deadline) returns(uint[] memory amounts) {
        address[] memory recipients;
        (amounts, recipients) = getAmountsIn(amountOut, path, to);
        require(amountInMax >= amounts[0], "CowswapRouter: EXCESSIVE_INPUT_AMOUNT");

        if(msg.value >= amounts[0] && path[0] == WETH) {
            IWETH(WETH).deposit{value: amounts[0]}();
            assert(IWETH(WETH).transfer(recipients[0], amounts[0]));
        } else {
            IERC20(path[0]).transferFrom(msg.sender, recipients[0], amounts[0]);
        }

        receiveETH = receiveETH && path[path.length - 1] == WETH;
        if(receiveETH) {
            recipients[recipients.length - 1] = address(this);
        }

        for(uint i; i < path.length - 1; i++) {
            if(recipients[i] == dex) {
                StakeDex(dex).swap(path[i], path[i + 1], 0, recipients[i + 1]);
            } else {
                (address input, address output) = (path[i], path[i + 1]);
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
                pair.swap(amount0Out, amount1Out, recipients[i + 1], new bytes(0));
            }
        }

        if(receiveETH) {
            uint balanceWETH = IERC20(WETH).balanceOf(address(this));
            require(balanceWETH >= amountOut, "CowswapRouter: INSUFFICIENT_OUTPUT_AMOUNT");
            IWETH(WETH).withdraw(amountOut);
            TransferHelper.safeTransferETH(to, amountOut);
        }

        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);


        // pot.record(msg.sender, path[path.length - 1], amounts[amounts.length - 1]);
    }


    function getAmountsOut(
        uint amountIn, 
        address[] memory path, 
        address to
    ) public view returns(uint[] memory amounts, address[] memory recipients) {
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        recipients = new address[](path.length);
        recipients[path.length - 1] = to;

        for(uint i; i < path.length - 1; i++) {
            uint ammOut = amm_calcOutAmount(path[i], path[i + 1], amounts[i]);
            uint dexOut = dex_calcOutAmount(path[i], path[i + 1], amounts[i]);
            if(dexOut > 0 && dexOut > ammOut) {
                amounts[i + 1] = dexOut;
                recipients[i] = dex;
            } else {
                amounts[i + 1] = ammOut;
                recipients[i] = PancakeLibrary.pairFor(factory, path[i], path[i + 1]);
            }
        }
    }

    function getAmountsIn(
        uint amountOut, 
        address[] memory path, 
        address to
    ) public view returns(uint[] memory amounts, address[] memory recipients) {
        amounts = new uint[](path.length);
        amounts[path.length - 1] = amountOut;
        recipients = new address[](path.length);
        recipients[path.length - 1] = to;

        for (uint i = path.length - 1; i > 0; i--) {
            uint ammIn = amm_calcInAmount(path[i - 1], path[i], amounts[i]);
            uint dexIn = dex_calcInAmount(path[i - 1], path[i], amounts[i]);
            if(dexIn > 0 && ammIn > dexIn) {
                amounts[i - 1] = dexIn;
                recipients[i - 1] = dex;
            } else {
                amounts[i - 1] = ammIn;
                recipients[i - 1] = PancakeLibrary.pairFor(factory, path[i - 1], path[i]);
            }
        }
    }

    function dex_calcOutAmount(address tokenIn, address tokenOut, uint amountIn) public view returns(uint) {
        (uint256 outAmount, ) = StakeDex(dex).calcOutAmount(tokenIn, tokenOut, amountIn);
        return outAmount;
    }

    function dex_calcInAmount(address tokenIn, address tokenOut, uint amountOut) public view returns(uint) {
        (uint256 inAmount, ) = StakeDex(dex).calcInAmount(tokenIn, tokenOut, amountOut);
        return inAmount;
    }

    function amm_calcOutAmount(address tokenIn, address tokenOut, uint amountIn) public view returns(uint) {
        return PancakeLibrary.calcOutAmount(factory, tokenIn, tokenOut, amountIn);
    }

    function amm_calcInAmount(address tokenIn, address tokenOut, uint amountOut) public view returns(uint) {
        return PancakeLibrary.calcInAmount(factory, tokenIn, tokenOut, amountOut);
    }
}