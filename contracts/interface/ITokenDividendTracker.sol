pragma solidity ^0.8.0;

interface ITokenDividendTracker {

    function controller() external view returns(address);

    function distributeDividends(uint256 amount) external;

    function setController(address cntr) external;

    function excludeFromDividends(address account) external;

    function updateClaimWait(uint256 newClaimWait) external;

    function getLastProcessedIndex() external view returns(uint256);

    function getNumberOfTokenHolders() external view returns(uint256);

    function getAccount(address _account)
        external view returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable);

     function getAccountAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256);

    function setBalance(address payable account, uint256 newBalance) external;

    function process(uint256 gas) external returns (uint256, uint256, uint256);

    function processAccount(address payable account, bool automatic) external returns(bool);
}