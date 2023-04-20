pragma solidity ^0.8.4;

interface ILPManager {
    event PoolCreated(address indexed token, address pool, uint);
    event EthPoolCreated(address pool);
    event LiquidityAdded(address indexed token, address to, uint);
    event EthLiquidityAdded(address to, uint);
    event LiquidityRemoved(address indexed token, address to, uint);
    event EthLiquidityRemoved(address to, uint);
    event LiquidityWithdraw(address indexed token, address to, uint amount);
    event EthLiquidityWithdraw(address to, uint amount);
    event RewardsAdded(address indexed token, uint amount);
    event EthRewardsAdded(uint amount);
    function createPool(address token) external returns (address pool);
    function createEthPool() external returns (address pool);
    function removeLiquidity(address token, uint liquidity, address to) external returns (uint amount);
    function removeEthLiquidity(uint liquidity, address to) external returns (uint amount);
    function addLiquidity(address token, uint amount, address to) external returns (uint liquidity);
    function addEthLiquidity(address to) external payable returns (uint liquidity);
    function getPoolReservesViaToken(address token) external view returns(uint reserves);
    function getEthPoolReserves() external view returns(uint reserves);
    function getPoolBalanceViaToken(address token) external view returns(uint balance);
    function getEthPoolBalance() external view returns(uint balance);
    function deposit(address token, uint amount) external;
    function depositEth() external payable;
    function withdraw(address token, address to, uint amount) external;
    function withdrawEth(address to, uint amount) external;
    function addRewards(address token, uint amount) external;
    function addEthRewards() external payable;
    function pause() external;
    function unpause() external;
    function pauseToken(address token) external;
    function unpauseToken(address token) external;
    function pauseEth() external;
    function unpauseEth() external;
}

