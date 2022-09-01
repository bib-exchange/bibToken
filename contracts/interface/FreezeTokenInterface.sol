pragma solidity ^0.8.0;

interface FreezeTokenInterface {
    
    function getFreezeAmount(address _account) external view returns(uint256);

}