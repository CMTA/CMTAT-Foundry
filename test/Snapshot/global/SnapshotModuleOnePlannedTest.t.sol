///SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.17;
import "../../HelperContract.sol";
import "./SnapshotModuleUtils/SnapshotingModuleConfig.sol";
contract OnePlannedSnapshotTest is SnapshotingModuleConfig {
    uint256 snapshotTime;
    uint256 beforeSnapshotTime;
    uint256 initBlockTimeStamp = 200;

    function setUp() public {
        SnapshotingModuleConfig.config();
        snapshotTime = block.timestamp + 1;
        beforeSnapshotTime = block.timestamp - 60;
        vm.prank(OWNER);
        CMTAT_CONTRACT.scheduleSnapshot(snapshotTime);

        // Timeout
        vm.warp(initBlockTimeStamp + 200);
    }

    function testCanMintTokens() public {
        // Arrange - Assert
        uint256 resUint256;
        resUint256 = CMTAT_CONTRACT.snapshotTotalSupply(block.timestamp);
        assertEq(resUint256, 96);
        resUint256 = CMTAT_CONTRACT.snapshotBalanceOf(
            block.timestamp,
            ADDRESS1
        );
        assertEq(resUint256, 31);
        resUint256 = CMTAT_CONTRACT.snapshotBalanceOf(
            block.timestamp,
            ADDRESS2
        );
        assertEq(resUint256, 32);
        // Act
        vm.prank(OWNER);
        CMTAT_CONTRACT.mint(ADDRESS1, 20);
        // Assert
        // Values before the snapshot
        resUint256 = CMTAT_CONTRACT.snapshotTotalSupply(beforeSnapshotTime);
        assertEq(resUint256, 96);
        resUint256 = CMTAT_CONTRACT.snapshotBalanceOf(
            beforeSnapshotTime,
            ADDRESS1
        );
        assertEq(resUint256, 31);
        resUint256 = CMTAT_CONTRACT.snapshotBalanceOf(
            beforeSnapshotTime,
            ADDRESS2
        );
        assertEq(resUint256, 32);
        // Values now
        resUint256 = CMTAT_CONTRACT.snapshotTotalSupply(block.timestamp);
        assertEq(resUint256, 116);
        resUint256 = CMTAT_CONTRACT.snapshotBalanceOf(
            block.timestamp,
            ADDRESS1
        );
        assertEq(resUint256, 51);
        resUint256 = CMTAT_CONTRACT.snapshotBalanceOf(
            block.timestamp,
            ADDRESS2
        );
        assertEq(resUint256, 32);
        uint256[] memory snapshots = CMTAT_CONTRACT.getNextSnapshots();
        assertEq(snapshots.length, 0);
    }

    function testCanBurnTokens() public {
        // Arrange - Assert
        uint256 resUint256;
        vm.prank(ADDRESS1);
        CMTAT_CONTRACT.approve(OWNER, 50);
        resUint256 = CMTAT_CONTRACT.snapshotTotalSupply(block.timestamp);
        assertEq(resUint256, 96);
        resUint256 = CMTAT_CONTRACT.snapshotBalanceOf(
            block.timestamp,
            ADDRESS1
        );
        assertEq(resUint256, 31);
        resUint256 = CMTAT_CONTRACT.snapshotBalanceOf(
            block.timestamp,
            ADDRESS2
        );
        assertEq(resUint256, 32);
        // Act
        vm.prank(OWNER);
        CMTAT_CONTRACT.forceBurn(ADDRESS1, 20);
        // Assert
        // Values before the snapshot
        resUint256 = CMTAT_CONTRACT.snapshotTotalSupply(beforeSnapshotTime);
        assertEq(resUint256, 96);
        resUint256 = CMTAT_CONTRACT.snapshotBalanceOf(
            beforeSnapshotTime,
            ADDRESS1
        );
        assertEq(resUint256, 31);
        resUint256 = CMTAT_CONTRACT.snapshotBalanceOf(
            beforeSnapshotTime,
            ADDRESS2
        );
        assertEq(resUint256, 32);
        // Values now
        resUint256 = CMTAT_CONTRACT.snapshotTotalSupply(block.timestamp);
        assertEq(resUint256, 76);
        resUint256 = CMTAT_CONTRACT.snapshotBalanceOf(
            block.timestamp,
            ADDRESS1
        );
        assertEq(resUint256, 11);
        resUint256 = CMTAT_CONTRACT.snapshotBalanceOf(
            block.timestamp,
            ADDRESS2
        );
        assertEq(resUint256, 32);
        uint256[] memory snapshots = CMTAT_CONTRACT.getNextSnapshots();
        assertEq(snapshots.length, 0);
    }

    function testCanTransferTokens() public {
        uint256 resUint256;
        resUint256 = CMTAT_CONTRACT.snapshotTotalSupply(block.timestamp);
        assertEq(resUint256, 96);
        resUint256 = CMTAT_CONTRACT.snapshotBalanceOf(
            block.timestamp,
            ADDRESS1
        );
        assertEq(resUint256, 31);
        resUint256 = CMTAT_CONTRACT.snapshotBalanceOf(
            block.timestamp,
            ADDRESS2
        );
        assertEq(resUint256, 32);
        vm.prank(ADDRESS1);
        // Act
        CMTAT_CONTRACT.transfer(ADDRESS2, 20);
        // Assert
        // Values before the snapshot
        resUint256 = CMTAT_CONTRACT.snapshotTotalSupply(beforeSnapshotTime);
        assertEq(resUint256, 96);
        resUint256 = CMTAT_CONTRACT.snapshotBalanceOf(
            beforeSnapshotTime,
            ADDRESS1
        );
        assertEq(resUint256, 31);
        resUint256 = CMTAT_CONTRACT.snapshotBalanceOf(
            beforeSnapshotTime,
            ADDRESS2
        );
        assertEq(resUint256, 32);
        // Values now
        resUint256 = CMTAT_CONTRACT.snapshotTotalSupply(block.timestamp);
        assertEq(resUint256, 96);
        resUint256 = CMTAT_CONTRACT.snapshotBalanceOf(
            block.timestamp,
            ADDRESS1
        );
        assertEq(resUint256, 11);
        resUint256 = CMTAT_CONTRACT.snapshotBalanceOf(
            block.timestamp,
            ADDRESS2
        );
        assertEq(resUint256, 52);
        uint256[] memory snapshots = CMTAT_CONTRACT.getNextSnapshots();
        assertEq(snapshots.length, 0);
    }
}