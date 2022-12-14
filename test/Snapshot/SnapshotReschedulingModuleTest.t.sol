//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.17;
import "../HelperContract.sol";

// Snapshot rescheduling
contract SnapshotReschedulingModuleTest is
    HelperContract,
    Test,
    SnasphotModule
{
    uint256 snapshotTime;
    uint256 newSnapshotTime;

    function setUp() public {
        vm.prank(OWNER);
        vm.warp(100);
        CMTAT_CONTRACT = new CMTAT(ZERO_ADDRESS, false,
            OWNER,
            "CMTA Token",
            "CMTAT",
            "CMTAT_ISIN",
            "https://cmta.ch");

        // Config personal
        snapshotTime = block.timestamp + 60;
        newSnapshotTime = block.timestamp + 90;
        vm.prank(OWNER);
        CMTAT_CONTRACT.scheduleSnapshot(snapshotTime);
    }

    // can reschedule a snapshot with the snapshoter role and emits a SnapshotSchedule event
    function testRescheduleSnapshot() public {
        vm.prank(OWNER);
        vm.expectEmit(true, true, false, false);
        emit SnapshotSchedule(snapshotTime, newSnapshotTime);
        CMTAT_CONTRACT.rescheduleSnapshot(snapshotTime, newSnapshotTime);
        uint256[] memory snapshots = CMTAT_CONTRACT.getNextSnapshots();
        assertEq(snapshots.length, 1);
        assertEq(snapshots[0], newSnapshotTime);
    }

    // reverts when calling from non-owner
    function testCannotRescheduleByNonOwner() public {
        string memory message = string(
            abi.encodePacked(
                "AccessControl: account ",
                vm.toString(ADDRESS1),
                " is missing role ",
                SNAPSHOOTER_ROLE_HASH
            )
        );
        vm.expectRevert(bytes(message));
        vm.prank(ADDRESS1);
        CMTAT_CONTRACT.rescheduleSnapshot(snapshotTime, newSnapshotTime);
    }

    // reverts when trying to reschedule a snapshot in the past
    function testCannotRescheduleSchapshotInThePast() public {
        vm.prank(OWNER);
        vm.expectRevert(bytes("Snapshot scheduled in the past"));
        CMTAT_CONTRACT.rescheduleSnapshot(snapshotTime, block.timestamp - 60);
    }

    // reverts when trying to schedule a snapshot with the same time twice
    function testCannotRescheduleSameTimeTwice() public {
        vm.prank(OWNER);
        CMTAT_CONTRACT.rescheduleSnapshot(snapshotTime, newSnapshotTime);
        vm.prank(OWNER);
        vm.expectRevert(bytes("Snapshot already scheduled for this time"));
        CMTAT_CONTRACT.rescheduleSnapshot(snapshotTime, newSnapshotTime);
        uint256[] memory snapshots = CMTAT_CONTRACT.getNextSnapshots();
        assertEq(snapshots.length, 1);
        assertEq(snapshots[0], newSnapshotTime);
    }

    // reverts when snapshot is not found
    function testCannotRescheduleNotFoundSnapshot() public {
        vm.prank(OWNER);
        vm.expectRevert(bytes("Snapshot not found"));
        CMTAT_CONTRACT.rescheduleSnapshot(
            block.timestamp + 90,
            newSnapshotTime
        );
    }

    // reverts when snapshot has been processed
    function testCannotReschuleProcessedSnapshot() public {
        vm.prank(OWNER);
        vm.expectRevert(bytes("Snapshot already done"));
        CMTAT_CONTRACT.rescheduleSnapshot(
            block.timestamp - 60,
            newSnapshotTime
        );
    }
}
