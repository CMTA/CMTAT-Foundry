///SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.17;
import "../../HelperContract.sol";

contract SnapshotUnSchedulingModuleTest is
    Test,
    HelperContract,
    SnapshotModule
{
    uint256 snapshotTime;

    function setUp() public {
        vm.warp(200);
        vm.prank(OWNER);
        CMTAT_CONTRACT = new CMTAT(ZERO_ADDRESS, false,
            OWNER,
            "CMTA Token",
            "CMTAT",
            "CMTAT_ISIN",
            "https://cmta.ch");

        // Config personal
        snapshotTime = block.timestamp + 60;
        vm.prank(OWNER);
        CMTAT_CONTRACT.scheduleSnapshot(snapshotTime);
    }

    // can unschedule a snapshot with the snapshoter role and emits a SnapshotUnschedule event
    function testUnscheduleSnapshot() public {
        vm.prank(OWNER);
        vm.expectEmit(true, false, false, false);
        emit SnapshotUnschedule(snapshotTime);
        CMTAT_CONTRACT.unscheduleLastSnapshot(snapshotTime);
        uint256[] memory snapshots = CMTAT_CONTRACT.getNextSnapshots();
        assertEq(snapshots.length, 0);
    }

    // reverts when calling from non-owner
    function testCannotCallByNonOwner() public {
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
        CMTAT_CONTRACT.unscheduleLastSnapshot(snapshotTime);
    }

    // reverts when snapshot is not found
    function testCannotSnapshotIsNotFound() public {
        vm.prank(OWNER);
        vm.expectRevert(bytes("Only the last snapshot can be unscheduled"));
        CMTAT_CONTRACT.unscheduleLastSnapshot(block.timestamp + 90);
    }

    // reverts when snapshot has been processed
    function testCannotUnscheduleProcessedSnapshot() public {
        vm.prank(OWNER);
        vm.expectRevert(bytes("Snapshot already done"));
        CMTAT_CONTRACT.unscheduleLastSnapshot(block.timestamp - 60);
    }
}