// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Init.t.sol";
import "../contracts/AlcRoyaltyOracle.sol";
import "../contracts/AlchemistDAO.sol";
contract AlchemistTest is InitTest {
    AlchemistDAO alchemistDAO;
    AlcRoyaltyOracle royaltyOracleOfAlchemist;
    function setUp() public virtual override {
        super.setUp();
        alchemistDAO = new AlchemistDAO(address(mic), address(alchemist), address(alchemistTreasury));
        royaltyOracleOfAlchemist = new AlcRoyaltyOracle(address(mic), 100 ether);
        mid.mintMid("test.mid");
        mid.mintMid("test1.mid");
        mid.mintMid("test2.mid");
        mid.mintMid("test3.mid");
    }
    function test_alchemist_cap() public {
        assertEq(alchemist.cap(), 3000);
    }

    function test_alchemist_pause() public {
       alchemist.pause();
    }

    function test_alchemist_unpause() public {
        test_alchemist_pause();
       alchemist.unpause();
    }


    function test_alchemist_mint() public {
        bytes memory data = abi.encodeWithSignature("grantRole(bytes32,address)", alchemist.ALCHEMIST_ROLE(), address(this));
        metaTimelockController.schedule(address(alchemist), 0, data, bytes32(0), bytes32(0), 2);
        skip(62);
        metaTimelockController.execute(address(alchemist), 0, data, bytes32(0), bytes32(0));
        alchemist.setAlchemist(address(this), 50);
        alchemist.mint();
        assertEq(address(this), alchemist.ownerOf(1000));
    }

    function test_alchemist_mintByContract() public {
        bytes memory data = abi.encodeWithSignature("grantRole(bytes32,address)", alchemist.ALCHEMIST_CONTRACT_ROLE(), address(this));
        metaTimelockController.schedule(address(alchemist), 0, data, bytes32(0), bytes32(0), 2);
        skip(62);
        metaTimelockController.execute(address(alchemist), 0, data, bytes32(0), bytes32(0));
        alchemist.mintByContract(address(this));
        assertEq(alchemist.ownerOf(1000), address(this));
    }

    function test_alchemist_ownerOfMinted() public {
        test_alchemist_mint();
        assertEq(alchemist.ownerOfMinted(address(this)), 1);
    }

    function test_alchemist_transfer() public {
        test_alchemist_mint();
        uint256 tokenId = 1000;
        bytes memory data = abi.encodeWithSignature("setRoyaltyOracle(address)", address(royaltyOracleOfAlchemist));
        metaTimelockController.schedule(address(alchemist), 0, data, bytes32(0), bytes32(0), 61);
        skip(62);
        metaTimelockController.execute(address(alchemist), 0, data, bytes32(0), bytes32(0));

        uint256 a = mic.balanceOf(address(alchemistTreasury));
        uint256 b = mic.balanceOf(address(micTreasury));
        uint256 c = mic.balanceOf(address(midLandTreasury));

        mic.approve(address(alchemist), 10000 ether);

        alchemist.transferFrom(address(this), address(mid), tokenId);
        assertEq(address(mid), alchemist.ownerOf(tokenId));

        alchemist.mint();
        uint256 tokenId2 = 1001;
        alchemist.transferFrom(address(this), address(mid), tokenId2);
        assertEq(address(mid), alchemist.ownerOf(tokenId2));

        /// Remove isContract() before test royalty
        // assertEq(mic.balanceOf(address(alchemistTreasury)) - a, 30 ether);
        // assertEq(mic.balanceOf(address(micTreasury)) - b, 20 ether);
        // assertEq(mic.balanceOf(address(midLandTreasury)) - c, 50 ether);
    }

    function test_alchemist_treasury() public {
        assertEq(alchemist.micTreasury(), address(micTreasury));
        assertEq(alchemist.alchemistTreasury(), address(alchemistTreasury));
        assertEq(alchemist.midLandTreasury(), address(midLandTreasury));
    }

    function test_alchemist_balance_of_treasury() public {
        assertEq(mic.balanceOf(address(micTreasury)), 800 ether);
        assertEq(mic.balanceOf(address(midLandTreasury)), 800 ether);
        assertEq(mic.balanceOf(address(alchemistTreasury)), 1200 ether);
    }

    function test_alchemist_royalteOracleAddress() public {
        test_alchemist_transfer();
        assertEq(alchemist.royalteOracleAddress(), address(royaltyOracleOfAlchemist));
    }

    /// Remove isContract() before test
    // function test_alchemist_previousOwnerOf() public {
    //     test_alchemist_mint();
    //     bytes memory data = abi.encodeWithSignature("setRoyaltyOracle(address)", address(royaltyOracleOfAlchemist));
    //     metaTimelockController.schedule(address(alchemist), 0, data, bytes32(0), bytes32(0), 61);
    //     skip(62);
    //     metaTimelockController.execute(address(alchemist), 0, data, bytes32(0), bytes32(0));

    //     mic.approve(address(alchemist), 10000 ether);
    //     alchemist.mint();
    //     uint256 tokenId = 1000;
    //     alchemist.transferFrom(address(this), address(mid), tokenId);
    //     assertEq(address(mid), alchemist.previousOwnerOf(tokenId));
    // }

}