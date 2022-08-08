// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Init.t.sol";
import "../contracts/MidRoyaltyOracle.sol";


abstract contract MidBaseTest is InitTest {
    function setUp() public virtual override {
        super.setUp();
    }

}