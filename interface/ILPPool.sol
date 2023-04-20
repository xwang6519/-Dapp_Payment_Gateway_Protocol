pragma solidity ^0.8.4;

interface ILPPool {
    function getReserves() external view returns (uint reserve, uint32 blockTimestampLast);
    function mint(address to, uint amount) external returns (uint liquidity);
    function burn(address to) external returns (uint amount);
    function addRewards(uint amount) external;
    function withdraw(address to, uint amount) external;
    function pause() external;
    function unpause() external;
}
