pragma solidity ^0.8.4;

interface IDIDRegistry {
    function registerDid(string memory did, string memory pubkey) external;
    function updateDid(string memory did, string memory pubkey) external;
    function getPublicKeyJwk(string memory did) view external returns(string memory pubkey);
}
