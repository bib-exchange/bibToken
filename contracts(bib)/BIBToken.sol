// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


contract BIBToken is Initializable, ERC20Upgradeable, PausableUpgradeable, OwnableUpgradeable {
/// @custom:oz-upgrades-unsafe-allow constructor
function initialize() initializer public {
    __ERC20_init("BIBToken", "BIB");
    __Pausable_init();
    __Ownable_init();
    _mint(msg.sender, 100000000000 * 10 ** decimals());
}

function pause() public onlyOwner {
    _pause();
}

function unpause() public onlyOwner {
    _unpause();
}

function _beforeTokenTransfer(address from, address to, uint256 amount) internal whenNotPaused override {
    super._beforeTokenTransfer(from, to, amount);
    }
}
