pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BEP20Token is ERC20 {
    constructor() public ERC20("Test USD Token","TestUSD")  {
      _mint(msg.sender, 1 * 10**9 * 10**18);
    }
}