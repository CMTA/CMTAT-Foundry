//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.17;
import "../HelperContract.sol";

// Snapshoting
contract SnapshotingModuleConfig is Test, HelperContract, SnasphotModule {
    function config() public {
        vm.warp(200);
        vm.prank(OWNER);
        CMTAT_CONTRACT = new CMTAT(ZERO_ADDRESS, false,
            OWNER,
            "CMTA Token",
            "CMTAT",
            "CMTAT_ISIN",
            "https://cmta.ch");

        // Config personal
        vm.prank(OWNER);
        CMTAT_CONTRACT.mint(ADDRESS1, 31);
        vm.prank(OWNER);
        CMTAT_CONTRACT.mint(ADDRESS2, 32);
        vm.prank(OWNER);
        CMTAT_CONTRACT.mint(ADDRESS3, 33);
    }
}

contract BeforeAnySnaphotTest is SnapshotingModuleConfig {
    function setUp() public {
        SnapshotingModuleConfig.config();
    }

    // context : Before any snapshot'
    // can get the total supply
    function testCanGetTotalSupply() public {
        uint256 res1 = CMTAT_CONTRACT.snapshotTotalSupply(block.timestamp);
        assertEq(res1, 96);
    }

    // can get the balance of an address
    function testCanGetBalanceAddress() public {
        uint256 res1 = CMTAT_CONTRACT.snapshotBalanceOf(
            block.timestamp,
            ADDRESS1
        );
        assertEq(res1, 31);
    }
}

// With one planned snapshot
contract onePlannedSnapshotTest is SnapshotingModuleConfig {
    uint256 snapshotTime;
    uint256 beforeSnapshotTime;
    uint256 initBlockTimeStamp = 200;

    function setUp() public {
        SnapshotingModuleConfig.config();
        snapshotTime = block.timestamp + 1;
        beforeSnapshotTime = block.timestamp - 60;
        vm.prank(OWNER);
        CMTAT_CONTRACT.scheduleSnapshot(snapshotTime);

        //Timeout
        vm.warp(initBlockTimeStamp + 200);
    }

    // can mint tokens
    function testCanMintTokens() public {
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
        vm.prank(OWNER);
        CMTAT_CONTRACT.mint(ADDRESS1, 20);
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

    // can burn tokens
    function testCanBurnTokens() public {
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
        vm.prank(OWNER);
        CMTAT_CONTRACT.forceBurn(ADDRESS1, 20);
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

    // can transfer tokens
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
        CMTAT_CONTRACT.transfer(ADDRESS2, 20);
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

// With multiple planned snapshot

contract SnapshotMultiplePlannedTest is SnapshotingModuleConfig {
    SnapshotingModuleConfig snapshotingModuleConfig =
        new SnapshotingModuleConfig();
    uint256 snapshotTime1;
    uint256 snapshotTime2;
    uint256 snapshotTime3;
    uint256 beforeSnapshotTime;

    function setUp() public {
        SnapshotingModuleConfig.config();

        //snapshotingModuleConfig.config();
        snapshotTime1 = block.timestamp + 1;
        snapshotTime2 = block.timestamp + 6;
        snapshotTime3 = block.timestamp + 11;
        beforeSnapshotTime = block.timestamp - 60;
        vm.prank(OWNER);
        CMTAT_CONTRACT.scheduleSnapshot(snapshotTime1);
        vm.prank(OWNER);
        CMTAT_CONTRACT.scheduleSnapshot(snapshotTime2);
        vm.prank(OWNER);
        CMTAT_CONTRACT.scheduleSnapshot(snapshotTime3);
        vm.warp(block.timestamp + 3);
        // await timeout(3000);
    }

    // can transfer tokens after first snapshot
    function testCanTransferTokensAfterFirstSnapshot() public {
        uint256 resUint256;
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
        CMTAT_CONTRACT.transfer(ADDRESS2, 20);
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
        console.log("***********", snapshots.length);
        assertEq(snapshots.length, 2);
    }

    // can transfer tokens after second snapshot
    function testCanTransferAfterSecondSnapshot() public {
        //Timeout
        vm.warp(snapshotTime2 + 1);
        uint256 resUint256;
        // await timeout(5000);
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
        CMTAT_CONTRACT.transfer(ADDRESS2, 20);
        resUint256 = CMTAT_CONTRACT.snapshotTotalSupply(snapshotTime1);
        assertEq(resUint256, 96);
        resUint256 = CMTAT_CONTRACT.snapshotBalanceOf(snapshotTime1, ADDRESS1);
        assertEq(resUint256, 31);
        resUint256 = CMTAT_CONTRACT.snapshotBalanceOf(snapshotTime1, ADDRESS2);
        assertEq(resUint256, 32);
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
        assertEq(snapshots.length, 1);
    }

    // can transfer tokens after third snapshot
    function testTransferAfterThirdSnapshot() public {
        uint256 resUint256;
        vm.warp(snapshotTime3 + 1);
        // await timeout(10000);
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
        CMTAT_CONTRACT.transfer(ADDRESS2, 20);
        resUint256 = CMTAT_CONTRACT.snapshotTotalSupply(snapshotTime1);
        assertEq(resUint256, 96);
        resUint256 = CMTAT_CONTRACT.snapshotBalanceOf(snapshotTime1, ADDRESS1);
        assertEq(resUint256, 31);
        resUint256 = CMTAT_CONTRACT.snapshotBalanceOf(snapshotTime1, ADDRESS2);
        assertEq(resUint256, 32);
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

    // can transfer tokens multiple times between snapshots
    function testTransferTokensMultipleTimes() public {
        uint256 resUint256;
        uint256[] memory snapshots;
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
        vm.warp(snapshotTime1 + 1);
        CMTAT_CONTRACT.transfer(ADDRESS2, 20);
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
        snapshots = CMTAT_CONTRACT.getNextSnapshots();
        assertEq(snapshots.length, 2);
        // await timeout(5000);
        //vm.warp(snapshotTime2 + 1);
        vm.prank(ADDRESS2);
        vm.warp(snapshotTime2 + 1);
        CMTAT_CONTRACT.transfer(ADDRESS1, 10);
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
        resUint256 = CMTAT_CONTRACT.snapshotTotalSupply(snapshotTime1);
        assertEq(resUint256, 96);
        resUint256 = CMTAT_CONTRACT.snapshotBalanceOf(snapshotTime1, ADDRESS1);
        assertEq(resUint256, 31);
        resUint256 = CMTAT_CONTRACT.snapshotBalanceOf(snapshotTime1, ADDRESS2);
        assertEq(resUint256, 32);
        resUint256 = CMTAT_CONTRACT.snapshotTotalSupply(snapshotTime2);
        assertEq(resUint256, 96);
        resUint256 = CMTAT_CONTRACT.snapshotBalanceOf(snapshotTime2, ADDRESS1);
        assertEq(resUint256, 11);
        resUint256 = CMTAT_CONTRACT.snapshotBalanceOf(snapshotTime2, ADDRESS2);
        assertEq(resUint256, 52);
        resUint256 = CMTAT_CONTRACT.snapshotTotalSupply(block.timestamp);
        assertEq(resUint256, 96);
        resUint256 = CMTAT_CONTRACT.snapshotBalanceOf(
            block.timestamp,
            ADDRESS1
        );
        assertEq(resUint256, 21);
        resUint256 = CMTAT_CONTRACT.snapshotBalanceOf(
            block.timestamp,
            ADDRESS2
        );
        assertEq(resUint256, 42);
        snapshots = CMTAT_CONTRACT.getNextSnapshots();
        assertEq(snapshots.length, 1);

        // await timeout(5000);
        vm.warp(snapshotTime3 + 1);
        vm.prank(ADDRESS1);
        CMTAT_CONTRACT.transfer(ADDRESS2, 5);
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
        resUint256 = CMTAT_CONTRACT.snapshotTotalSupply(snapshotTime1);
        assertEq(resUint256, 96);
        resUint256 = CMTAT_CONTRACT.snapshotBalanceOf(snapshotTime1, ADDRESS1);
        assertEq(resUint256, 31);
        resUint256 = CMTAT_CONTRACT.snapshotBalanceOf(snapshotTime1, ADDRESS2);
        assertEq(resUint256, 32);
        resUint256 = CMTAT_CONTRACT.snapshotTotalSupply(snapshotTime2);
        assertEq(resUint256, 96);
        resUint256 = CMTAT_CONTRACT.snapshotBalanceOf(snapshotTime2, ADDRESS1);
        assertEq(resUint256, 11);
        resUint256 = CMTAT_CONTRACT.snapshotBalanceOf(snapshotTime2, ADDRESS2);
        assertEq(resUint256, 52);
        resUint256 = CMTAT_CONTRACT.snapshotTotalSupply(snapshotTime3);
        assertEq(resUint256, 96);
        resUint256 = CMTAT_CONTRACT.snapshotBalanceOf(snapshotTime3, ADDRESS1);
        assertEq(resUint256, 21);
        resUint256 = CMTAT_CONTRACT.snapshotBalanceOf(snapshotTime3, ADDRESS2);
        assertEq(resUint256, 42);
        resUint256 = CMTAT_CONTRACT.snapshotTotalSupply(block.timestamp);
        assertEq(resUint256, 96);
        resUint256 = CMTAT_CONTRACT.snapshotBalanceOf(
            block.timestamp,
            ADDRESS1
        );
        assertEq(resUint256, 16);
        resUint256 = CMTAT_CONTRACT.snapshotBalanceOf(
            block.timestamp,
            ADDRESS2
        );
        assertEq(resUint256, 47);
        snapshots = CMTAT_CONTRACT.getNextSnapshots();
        assertEq(snapshots.length, 0);
    }
}
