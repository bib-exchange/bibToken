pragma solidity 0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";

contract FreezeToken is Ownable {

    mapping (address => uint256) public freezeMap;
    address public cntr;

    constructor(address _cntr)  {
        require(address(0) == cntr, "INVLID_ADDR");
        cntr = _cntr;
    }

    function controller() public view returns(address){
        return cntr;
    }

    function setController(address _cntr) public {
        require(address(0) == cntr, "INVLID_ADDR");
        cntr = _cntr;
    }

    modifier onlyController {
        require(msg.sender == cntr, "ONLY_CONTROLLER");
        _;
    }

    modifier onlyControllerOrOwner {
        require(msg.sender == cntr || msg.sender == owner(), "ONLY_CONTROLLER_OR_OWNER");
        _;
    }

    function _addFreezeToken(address account, uint256 amount) internal {
        freezeMap[account] = freezeMap[account] + amount;
    }

    function addFreezeToken(address account, uint256 amount) onlyControllerOrOwner external {
        _addFreezeToken(account, amount);
    }

    function getFreezeAmount(address _account) external view returns(uint256) {
        return freezeMap[_account];
    }
}