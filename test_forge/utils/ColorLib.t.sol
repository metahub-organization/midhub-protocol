// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@std/Test.sol";
import "../../contracts/utils/Uints.sol";
contract ColorLibTest is Test {
    function setUp() public {

    }
    function test_color() public {
        string memory colors = Uints.uintToHex(100098797657);
        assertEq("#9507A5", colors);
    }
}
