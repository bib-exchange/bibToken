// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/finance/VestingWallet.sol";

contract VestingToken is VestingWallet{
    constructor(
        address beneficiaryAddress,
        uint64 startTimestamp,
        uint64 durationSeconds
    ) VestingWallet(beneficiaryAddress, startTimestamp, durationSeconds){}

    receive() external payable override {
        revert("UNSUPPORTED_OP");
    }

    function release() public override {
        revert("UNSUPPORTED_OP");
    }
}