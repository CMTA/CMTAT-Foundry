//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.17;
import "../HelperContract.sol";

contract SnapshotSchedulingModuleTest is Test, HelperContract, SnapshotModule {
    uint256 snapshotTime;

    function setUp() public {
        vm.warp(100);
        snapshotTime = block.timestamp + 60;
        vm.prank(OWNER);
        CMTAT_CONTRACT = new CMTAT(ZERO_ADDRESS, false,
            OWNER,
            "CMTA Token",
            "CMTAT",
            "CMTAT_ISIN",
            "https://cmta.ch");
    }

    // can schedule a snapshot with the snapshoter role
    function testCanScheduleSnapshotAsSnapshoter() public {
        vm.prank(OWNER);
        vm.expectEmit(true, true, false, false);
        emit SnapshotSchedule(0, snapshotTime);
        CMTAT_CONTRACT.scheduleSnapshot(snapshotTime);
        uint256[] memory snapshots = CMTAT_CONTRACT.getNextSnapshots();
        assertEq(snapshots.length, 1);
        assertEq(snapshots[0], snapshotTime);
    }

    // reverts when calling from non-owner
    function testCannotRevertCallByNonOwner() public {
        vm.prank(ADDRESS1);
        string memory message = string(
            abi.encodePacked(
                "AccessControl: account ",
                vm.toString(ADDRESS1),
                " is missing role ",
                SNAPSHOOTER_ROLE_HASH
            )
        );
        vm.expectRevert(bytes(message));
        CMTAT_CONTRACT.scheduleSnapshot(snapshotTime);
    }

    // reverts when trying to schedule a snapshot in the past
    function testCannotSheduleSnapshotInThePast() public {
        vm.prank(OWNER);
        vm.expectRevert(bytes("Snapshot scheduled in the past"));
        CMTAT_CONTRACT.scheduleSnapshot(block.timestamp - 60);
    }

    // reverts when trying to schedule a snapshot with the same time twice
    function testCannotScheduleSnaphostSameTime() public {
        vm.prank(OWNER);
        console.log("sT", snapshotTime);
        console.log("bt", block.timestamp);
        CMTAT_CONTRACT.scheduleSnapshot(snapshotTime);
        vm.prank(OWNER);
        vm.expectRevert(bytes("time has to be greater than the last snapshot time"));
        CMTAT_CONTRACT.scheduleSnapshot(snapshotTime);
        uint256[] memory snapshots = CMTAT_CONTRACT.getNextSnapshots();
        assertEq(snapshots.length, 1);
        assertEq(snapshots[0], snapshotTime);
    }
}

