// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

enum VaultStatus {INUSE, AVAILABLE}

struct VaultInfo {
    string vaultAddress;
    VaultStatus status;
}

interface IAddressPool {
    // get an available payment vault from address pool to receive payments
    function getAvailableVault(string memory chain) external view returns (string memory vaultAddress);
    // use vault to receive payment, the vault status will be set to INUSE
    function useVault(uint index_, string memory chain, string memory vaultAddress) external;
    // get an available payment vault from address pool to receive payments and set status to INUSE
    function useAvailableVault(uint index_, string memory chain) external returns (string memory vaultAddress);
    // return a payment vault to the address pool, the vault status will be set to AVAILABLE and be able be selected for next payment
    function releaseVault(string memory chain, string memory vaultAddress) external;
    // add a new payment vault address into the address pool, the vault status will be set to AVAILABLE
    function addNewVault(string memory chain, string memory vaultAddress) external;
    // clean all vaults from the address pool, and fill up the address with given vaults
    function resetVaults(string memory chain, string[] memory vaultAddresses) external;
    // get current status of the given vault
    function getVaultStatus(string memory chain, string memory vaultAddress) external view returns (string memory vaultStatus);
}

contract AddressPool is Ownable, IAddressPool {

    enum RequestStatus {PENDING, CANCELED, COMPLETED, FAILED}

    struct Request {
        string requester; // sender of the request.
        string token;
        uint amount; // amount of token to deposit/withdraw.
        string txid; // asset txid for the deposit/withdraw process.
        string vault;
        uint nonce; // serial number allocated for each request.
        uint timestamp; // time of the request creation.
        RequestStatus status; // status of the request.
    }

    Request[] public paymentRequests;
    Request[] public withdrawRequests;

    mapping(string=>VaultInfo[]) public vaults;
    string[] public supportedChains;
    // vault chain => (address => vault nonce)
    mapping(string=>mapping(string=>uint)) public vaultInfoNonce;

    // mapping between a payment request hash and the corresponding request nonce.
    mapping(bytes32=>uint) public paymentRequestNonce;
    // txid => payment request hash
    mapping(string=>bytes32) public paymentRequestTxid;

    mapping(bytes32=>uint) public withdrawRequestNonce;
    mapping(string=>bytes32) public withdrawRequestTxid;

    // vault address => (token ==> balance)
    mapping(string=>mapping(string=>uint)) public vaultTokenBalance;

    constructor() {
        supportedChains.push("ETH");
        supportedChains.push("TRON");
    }

    event PaymentRequestAdd(
        uint indexed nonce,
        string indexed requester,
        string indexed token,
        uint amount,
        string txid,
        string vault,
        uint timestamp,
        bytes32 requestHash
    );

    function getTimestamp() internal view returns (uint) {
        // timestamp is only used for data maintaining purpose, it is not relied on for critical logic.
        return block.timestamp; // solhint-disable-line not-rely-on-time
    }

    function compareStrings (string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b)));
    }

    function isEmptyString (string memory a) internal pure returns (bool) {
        return (compareStrings(a, ""));
    }

    function useAvailableVault(uint index_, string memory chain_) external override onlyOwner returns (string memory vaultAddress) {
        vaultAddress = getAvailableVault(chain_);
        useVault(index_, chain_, vaultAddress);
    }

    function getAvailableVault(string memory chain_) public view override returns (string memory vaultAddress) {
        vaultAddress = "no available vault";
        for (uint i = 0; i < vaults[chain_].length; i++) {
            VaultInfo storage vault = vaults[chain_][i];
            if (vault.status == VaultStatus.AVAILABLE) {
                vaultAddress = vault.vaultAddress;
                break;
            }
        }
    }

    event UsingVault(
        uint index,
        string chain,
        string vaultAddress
    );

    function useVault(uint index_, string memory chain_, string memory vaultAddress_) public override onlyOwner {
        uint vaultNonce = vaultInfoNonce[chain_][vaultAddress_];
        string memory vaultAddress = vaults[chain_][vaultNonce].vaultAddress;
        require(compareStrings(vaultAddress, vaultAddress_), "unrecognized vault address");
        vaults[chain_][vaultNonce].status = VaultStatus.INUSE;
        emit UsingVault(index_, chain_, vaultAddress_);
    }

    event VaultReleased(
        string chain,
        string vaultAddress
    );

    function releaseVault(string memory chain_, string memory vaultAddress_) external override onlyOwner {
        uint vaultNonce = vaultInfoNonce[chain_][vaultAddress_];
        string memory vaultAddress = vaults[chain_][vaultNonce].vaultAddress;
        require(compareStrings(vaultAddress, vaultAddress_), "unrecognized vault address");
        vaults[chain_][vaultNonce].status = VaultStatus.AVAILABLE;
        emit VaultReleased(chain_, vaultAddress_);
    }

    event AddedNewVault(
        string chain,
        string vaultAddress,
        uint nonce
    );
    
    function addNewVault(string memory chain_, string memory vaultAddress_) external override onlyOwner {
        uint vaultNonce = vaults[chain_].length;
        vaults[chain_].push(VaultInfo({
            vaultAddress: vaultAddress_,
            status: VaultStatus.AVAILABLE
        }));
        vaultInfoNonce[chain_][vaultAddress_]=vaultNonce;

        emit AddedNewVault(chain_, vaultAddress_, vaultNonce);
    }

    event ResetVaults(
        string chain,
        uint numberOfvaults
    );
    function resetVaults(string memory chain_, string[] memory vaultAddresses_) external override onlyOwner {
        for (uint i = 0; i < vaults[chain_].length; i++) {
            delete vaultInfoNonce[chain_][vaults[chain_][i].vaultAddress];
        }
        while (vaults[chain_].length != 0) {
            vaults[chain_].pop();
        }

        for (uint i = 0; i < vaultAddresses_.length; i++) {
            require(!isEmptyString(vaultAddresses_[i]), "invalid vault address");
            vaults[chain_].push(VaultInfo({
                vaultAddress: vaultAddresses_[i],
                status: VaultStatus.AVAILABLE
            }));
            vaultInfoNonce[chain_][vaultAddresses_[i]] = i;
        }
        emit ResetVaults(chain_, vaultAddresses_.length);
    }

    function getVaultStatus(string memory chain_, string memory vaultAddress_) external override view returns (string memory vaultStatus) {
        require(!isEmptyString(vaultAddress_), "invalid vault address");
        uint vaultNonce = vaultInfoNonce[chain_][vaultAddress_];
        string memory vaultAddress = vaults[chain_][vaultNonce].vaultAddress;
        require(compareStrings(vaultAddress, vaultAddress_), "unrecognized vault address");
        if (vaults[chain_][vaultNonce].status == VaultStatus.AVAILABLE) {
            vaultStatus = "AVAILABLE";
        } else {
            vaultStatus = "INUSE";
        }
    }
}
