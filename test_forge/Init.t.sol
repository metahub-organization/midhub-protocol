// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../lib/forge-std/src/Test.sol";
import "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import "../contracts/USDC.sol";
import "../contracts/DNS/NNSRegistry.sol";
import "../contracts/MetaTimelockController.sol";
import "../contracts/TreasuryTimelockController.sol";
import "../contracts/Land.sol";
import "../contracts/Mid.sol";
import "../contracts/Mic.sol";
import "../contracts/AlchemistTreasury.sol";
import "../contracts/MidLandTreasury.sol";
import "../contracts/MicTreasury.sol";
import "../contracts/FundTreasury.sol";
import "../contracts/Alchemist.sol";
import "./utils/tokens/WETH.sol";

abstract contract InitTest is Test, ERC721Holder, ERC1155Holder {
    USDC usdc;
    NNSRegistry nns;
    MetaTimelockController metaTimelockController;
    Mid mid;
    Land land;
    Mic mic;
    Alchemist alchemist;
    MidLandTreasury midLandTreasury;
    MicTreasury micTreasury;
    AlchemistTreasury alchemistTreasury;
    TreasuryTimelockController treasuryTimelockController;
    FundTreasury fundTreasury;
    WETH internal weth;
    bytes32 private constant ROOT_NODE = bytes32(0);

    VRFCoordinatorV2Mock public vrfCoordinator;
    uint64 subId;
    bytes32 keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;
    uint96 constant MOCK_BASE_FEE = 100000000000000000;
    uint96 constant MOCK_GAS_PRICE_LINK = 1e9;

    function setUp() public virtual {
        weth = new WETH();
        usdc = new USDC();
        nns = new NNSRegistry();
        address[] memory proposersUser = new address[](1);
        proposersUser[0] = address(this);
        metaTimelockController = new MetaTimelockController(1, proposersUser, proposersUser);
        treasuryTimelockController = new TreasuryTimelockController(1, proposersUser, proposersUser);
        
        micTreasury = new MicTreasury(address(weth),
        address(treasuryTimelockController));
        midLandTreasury = new MidLandTreasury(address(weth),
        address(treasuryTimelockController));
        alchemistTreasury = new AlchemistTreasury(address(weth),
        address(treasuryTimelockController));
        fundTreasury = new FundTreasury(address(weth),
        address(treasuryTimelockController));

        alchemist = new Alchemist(address(metaTimelockController),
        address(0),
        micTreasury,
        midLandTreasury,
        alchemistTreasury);

        vrfCoordinator = new VRFCoordinatorV2Mock(MOCK_BASE_FEE, MOCK_GAS_PRICE_LINK);
        subId = vrfCoordinator.createSubscription();
        vrfCoordinator.fundSubscription(subId, 10 * 10**18);
        mid = new Mid(
        nns,
        address(metaTimelockController),
        address(0),
        micTreasury,
        midLandTreasury,
        alchemistTreasury,
        fundTreasury,
        address(vrfCoordinator)
        );
        vrfCoordinator.addConsumer(subId, address(mid));
        
        mic = new Mic(address(mid));

        land = new Land(
            nns,
            address(metaTimelockController),
            address(0),
            micTreasury,
            midLandTreasury,
            alchemistTreasury,
            address(mic),
            address(mid));

        // init
        mid.init(address(mic), address(land), usdc);
        bytes memory data = abi.encodeWithSignature("grantRole(bytes32,address)", mid.VRF_ROLE(), address(this));
        metaTimelockController.schedule(address(mid), 0, data, bytes32(0), bytes32(0), 61);
        skip(62);
        metaTimelockController.execute(address(mid), 0, data, bytes32(0), bytes32(0));
        mid.setVRF(
            keyHash,
            subId,
            200000,
            4);

        nns.setApprovalForAll(address(land), true);
        bytes32 landLabel = keccak256(bytes("land"));
        nns.setSubnodeOwner(ROOT_NODE, landLabel, address(land));

        // mint
        land.mint("mid.land");

        usdc.mint();
        usdc.approve(address(mid), 1000000 ether);

    }
}