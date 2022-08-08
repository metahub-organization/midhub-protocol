// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Alchemist.t.sol";

contract AlchemistDAOTest is AlchemistTest {
    function setUp() public override {
        super.setUp();
        bytes memory data = abi.encodeWithSignature("grantRole(bytes32,address)", alchemistTreasury.SETTLEMENT_ROLE(), address(alchemistDAO));
        treasuryTimelockController.schedule(address(alchemistTreasury), 0, data, bytes32(0), bytes32(0), 2);
        skip(62);
        treasuryTimelockController.execute(address(alchemistTreasury), 0, data, bytes32(0), bytes32(0));
    }
    function test_alchemistDAO_totalWithdrawalOf() public {
        assertEq(alchemistDAO.totalWithdrawalOf(), 0 ether);
    }

    function test_alchemistDAO_withdraw() public {
        test_alchemist_mint();
        assertEq(alchemistDAO.withdraw(1000), 4 * 10**17);
    }
}