## LP Manager Contract:
Contract address: https://goerli.etherscan.io/address/0xdD854d6f073354038d6B6Ea1Eb57fA8Cc1875b91

### API:
```solidity
interface ILPManager {
    event PoolCreated(address indexed token, address pool, uint);
    event LiquidityAdded(address indexed token, address to, uint);
    event LiquidityRemoved(address indexed token, address to, uint);
    // Create LP Pool for given token
    function createPool(address token) external returns (address pool);
    // Removing "Liquidity" (LP token) of "token" (e.g. USDC) and send them back to "to" address  
    function removeLiquidity(address token, uint liquidity, address to) external returns (uint amount);
    // Adding "amount" of "token" (e.g. USDC) and send liquidity(LP token) to "to" address
    function addLiquidity(address token, uint amount, address to) external returns (uint liquidity);
}
```
## Test Token:
- USDC: https://goerli.etherscan.io/address/0x4600029b3b2426d627dFde7d57AbCFdC96aEC147
- DAI: https://goerli.etherscan.io/address/0x581857409579161Dabd2C4994f78b2F1B3671bc2
- USDT: https://goerli.etherscan.io/address/0x875A48eD15d2B5ffB33097bDB402FaBfe1045880
- WBTC: https://goerli.etherscan.io/address/0x7B56fD31e25973F298C0c045c1Fe370111163161
- WETH: https://goerli.etherscan.io/address/0x39751FC445b4EAF409a8413246E1E2d9a615d7b3

## ARSW Token:
https://goerli.etherscan.io/address/0x497aFFcB5581eAA5684104A9CB6C4C49FC621291

## ARSW Farm:
https://goerli.etherscan.io/address/0xe48c7E55cd62585993a9048fd208290Bb1235F64
### API:
```solidity
interface ITokenStake {
    // add a new pool
    function addLPPool(address lpToken_, uint allocPoint_, uint lastRewardBlock_) external;
    // user deposit LP into a pool
    function depositLP(uint _pid, uint _amount) external;
    // query how much reward a user can claim from a pool 
    function pendingLPReward(uint _pid, address _user) public view returns (uint[] memory pending);
    // user withdraw LP from a pool 
    function withdrawLP(uint _pid, uint _amount) external;
}
```

## DIDRegistry Contract:

Contract address:
https://explorer.harmony.one/address/0x01fd38ca25cbb9e4c975b6ce329ca10153a8e927
https://goerli.etherscan.io/address/0x9B1b253Ab50970aD315F0a12F88e824070cd81F4



### API:
```solidity
interface IDIDRegistry {
    function registerDid(string memory did, string memory pubkey) external;
    function updateDid(string memory did, string memory pubkey) external;
    function getPublicKeyJwk(string memory did) view external returns(string memory pubkey);
    function getType() view external returns(string memory);
}
```
