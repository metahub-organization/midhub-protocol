// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./MidBase.t.sol";


contract MidTest is MidBaseTest {

    function test_mid_rarity() public {
        mid.mintMid("eth.mid");
        vrfCoordinator.fulfillRandomWords(1, address(mid));
        uint256 tokenId1 = mid.getTokenIdOfName("eth.mid");
        assertEq(mid.getProperty(tokenId1).rarity, bytes3("R"));
    }

    function test_mid_mint() public returns(uint256) {
        mic.approve(address(mid), 10000 ether);
        string memory name = "asdasdasdasdasda.mid";
        mid.mintMid(name);
        uint256 tokenId = mid.getTokenIdOfName(name);
        assertEq(address(this), mid.ownerOf(tokenId));
        return tokenId;
    }

    function test_mid_transfer() public {
        uint256 tokenId = test_mid_mint();
        MidRoyaltyOracle royaltyOracleOfMid = new MidRoyaltyOracle(address(mic), 1 ether);
        bytes memory data = abi.encodeWithSignature("setRoyaltyOracle(address)", address(royaltyOracleOfMid));
        metaTimelockController.schedule(address(mid), 0, data, bytes32(0), bytes32(0), 61);
        skip(62);
        metaTimelockController.execute(address(mid), 0, data, bytes32(0), bytes32(0));
        mid.mintMid("meme.mid");
        uint256 a = mic.balanceOf(address(alchemistTreasury));
        uint256 b = mic.balanceOf(address(micTreasury));
        uint256 c = mic.balanceOf(address(midLandTreasury));
        assertEq(address(this), mid.ownerOf(tokenId));
        // mid.transferFrom(address(this), address(land), tokenId);
        // assertEq(address(land), mid.ownerOf(tokenId));
        // uint256 tokenId2 = mid.getTokenIdOfName("meme.mid");
        // mid.transferFrom(address(this), address(land), tokenId2);
        // assertEq(mic.balanceOf(address(alchemistTreasury)) - a, 3 * 10**17);
        // assertEq(mic.balanceOf(address(micTreasury)) - b, 2 * 10**17);
        // assertEq(mic.balanceOf(address(midLandTreasury)) - c, 5 * 10**17);
    }

    function test_mid_mintRoute() public {
        bytes memory data = abi.encodeWithSignature("grantRole(bytes32,address)", mid.META_ID_CONTRACT_ROLE(), address(this));
        metaTimelockController.schedule(address(mid), 0, data, bytes32(0), bytes32(0), 61);
        skip(62);
        metaTimelockController.execute(address(mid), 0, data, bytes32(0), bytes32(0));

        mid.mintMid("test1.mid");
        mid.mintMid("test2.mid");
        mic.approve(address(land), 10000 ether);
        land.mint("id.land");

        string memory name = "test.id";
        mid.mintRoute(name, address(this));
        uint256 tokenId = mid.getTokenIdOfName(name);
        assertEq(address(this), mid.ownerOf(tokenId));
    }

}