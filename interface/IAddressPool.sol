pragma solidity ^0.8.4;

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
