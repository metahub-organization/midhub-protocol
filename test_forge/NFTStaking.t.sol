// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Alchemist.t.sol";
import "../contracts/staking/NFTStaking.sol";
import "../contracts/interfaces/IMid.sol";
contract NFTStakingTest is AlchemistTest {
    NFTStaking nftStaking;
    function setUp() public override {
        super.setUp();
        nftStaking = new NFTStaking(mic, IMid(address(mid)), micTreasury);
        
        bytes memory data = abi.encodeWithSignature("grantRole(bytes32,address)", micTreasury.SETTLEMENT_ROLE(), address(nftStaking));
        treasuryTimelockController.schedule(address(micTreasury), 0, data, bytes32(0), bytes32(0), 2);
        skip(62);
        treasuryTimelockController.execute(address(micTreasury), 0, data, bytes32(0), bytes32(0));
    }
    function test_nftStaking_updatePool() public {
        nftStaking.updatePool();
    }

    function test_nftStaking_deposit() public {
        vrfCoordinator.fulfillRandomWords(1, address(mid));
        test_nftStaking_updatePool();
        uint256 tokenId = mid.getTokenIdOfName("test.mid");
        nftStaking.deposit(tokenId);
        (uint256 pointsSupply, , ) = nftStaking.poolInfo();
        uint256 point = nftStaking.getPoints(tokenId);
        assertEq(point, pointsSupply);
        (uint256 userPoint,) = nftStaking.userInfo(tokenId);
        assertEq(point, userPoint);
    }

    function test_nftStaking_pendingToken() public {
        uint256 tokenId = mid.getTokenIdOfName("test.mid");
        nftStaking.deposit(tokenId);
        vm.roll(21);
        uint256 tokenId1 = mid.getTokenIdOfName("test1.mid");
        nftStaking.deposit(tokenId1);
        vm.roll(101);
        test_nftStaking_updatePool();
        uint256 tokenId2 = mid.getTokenIdOfName("test2.mid");
        nftStaking.deposit(tokenId2);
        vm.roll(121);
        uint256 reward = nftStaking.pendingToken(tokenId);
        uint256 reward2 = nftStaking.pendingToken(tokenId2);
        assertEq((reward / 1e14), (reward2 / 1e14));
    }

    function test_nftStaking_withdrawReward() public {
        uint256 balanceThis = mic.balanceOf(address(this)) / 1e16;
        nftStaking.updatePool();
        vrfCoordinator.fulfillRandomWords(1, address(mid));
        uint256 tokenId = mid.getTokenIdOfName("test.mid");
        nftStaking.deposit(tokenId);
        vm.roll(100);
        nftStaking.withdrawReward(tokenId);
        uint256 reward = mic.balanceOf(address(this)) / 1e16;
        uint256 balance = mic.balanceOf(address(nftStaking)) / 1e16;
        assertEq(balance, (16000 - (reward - balanceThis)));
    }

    function test_nftStaking_withdraw() public {
        nftStaking.updatePool();
        vrfCoordinator.fulfillRandomWords(1, address(mid));
        vrfCoordinator.fulfillRandomWords(2, address(mid));
        uint256 tokenId = mid.getTokenIdOfName("test.mid");
        nftStaking.deposit(tokenId);
        uint256 tokenId2 = mid.getTokenIdOfName("test1.mid");
        nftStaking.deposit(tokenId2);
        vm.roll(100);
        (uint256 pointsSupply, ,) = nftStaking.poolInfo();
        nftStaking.withdraw(tokenId);
        (uint256 pointsSupplyLast, , ) = nftStaking.poolInfo();
       assertEq(pointsSupply, pointsSupplyLast + nftStaking.getPoints(tokenId));
    }

    function test_nftStaking_emergencyWithdraw() public {
        uint256 tokenId = mid.getTokenIdOfName("test.mid");
        nftStaking.deposit(tokenId);
        uint256 tokenId2 = mid.getTokenIdOfName("test2.mid");
        nftStaking.deposit(tokenId2);
        vm.roll(100);
        (uint256 pointsSupply, ,) = nftStaking.poolInfo();
        nftStaking.emergencyWithdraw(tokenId);
        (uint256 pointsSupplyLast, , ) = nftStaking.poolInfo();
       assertEq(pointsSupply, pointsSupplyLast + nftStaking.getPoints(tokenId));
    }
}