// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
import "./Treasury.sol";

contract AlchemistTreasury is Treasury {
    constructor(address wethAddress_, address timelockController) Treasury(wethAddress_, timelockController) {}

}