
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
import "@openzeppelin/contracts/governance/TimelockController.sol";

contract TreasuryTimelockController is TimelockController {
    constructor(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors
    ) TimelockController(minDelay, proposers, executors) {}

}