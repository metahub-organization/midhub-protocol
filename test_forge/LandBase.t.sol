// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Init.t.sol";
import "../contracts/LandRoyaltyOracle.sol";

abstract contract LandBaseTest is InitTest{
    function setUp() public virtual override {
        super.setUp();
        mid.mintMid("test0.mid");
        mid.mintMid("test00.mid");
    }
}