//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.17;
import "../../HelperContract.sol";
import "./SnapshotModuleUtils/SnapshotingModuleConfig.sol";

contract ZeroPlannedSnapshotTest is SnapshotingModuleConfig {
    function setUp() public {
        SnapshotingModuleConfig.config();
    }

    // context : Before any snapshot'
    function testCanGetTotalSupply() public {
        // Act
        uint256 res1 = CMTAT_CONTRACT.snapshotTotalSupply(block.timestamp);
        // Assert
        assertEq(res1, 96);
    }

    function testCanGetBalanceAddress() public {
        // Act
        uint256 res1 = CMTAT_CONTRACT.snapshotBalanceOf(
            block.timestamp,
            ADDRESS1
        );
        // Assert
        assertEq(res1, 31);
    }
}



