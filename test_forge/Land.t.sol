// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./LandBase.t.sol";

contract LandTest is LandBaseTest {
    function setUp() public virtual override {
        super.setUp();
    }

    function test_land_mint() public returns(uint256 tokenId) {
        mic.approve(address(land), 10000 ether);
        land.mint("free.land");
        tokenId = land.getTokenIdOfName("free.land");
        assertEq(80488493578882676707511050447048175995489283190431746169453428712463013041724, tokenId);
        assertEq(address(this), land.ownerOf(tokenId));
    }

    function test_land_transfer() public {
        uint256 tokenId = test_land_mint();
        LandRoyaltyOracle royaltyOracleOfLand = new LandRoyaltyOracle(address(mic), 10 ether);
        bytes memory data = abi.encodeWithSignature("setRoyaltyOracle(address)", address(royaltyOracleOfLand));
        metaTimelockController.schedule(address(land), 0, data, bytes32(0), bytes32(0), 61);
        skip(62);
        metaTimelockController.execute(address(land), 0, data, bytes32(0), bytes32(0));
        mid.mintMid("test1.mid");
        mid.mintMid("test2.mid");
        land.mint("web3.land");
        uint256 a = mic.balanceOf(address(alchemistTreasury));
        uint256 b = mic.balanceOf(address(micTreasury));
        uint256 c = mic.balanceOf(address(midLandTreasury));

        land.transferFrom(address(this), address(mid), tokenId);
        uint256 tokenId2 = land.getTokenIdOfName("web3.land");
        land.transferFrom(address(this), address(mid), tokenId2);
        assertEq(address(mid), land.ownerOf(tokenId));
        /// Remove isContract() before test royalty
        // assertEq(mic.balanceOf(address(alchemistTreasury)) - a, 3 ether);
        // assertEq(mic.balanceOf(address(micTreasury)) - b, 2 ether);
        // assertEq(mic.balanceOf(address(midLandTreasury)) - c, 5 ether);
    }
}