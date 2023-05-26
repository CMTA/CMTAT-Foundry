//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "./HelperContract.sol";

contract PauseModuleTest is Test, HelperContract, PauseModule {
    
    function setUp() public {
        vm.prank(DEFAULT_ADMIN_ADDRESS);
        CMTAT_CONTRACT = new CMTAT_STANDALONE(
            ZERO_ADDRESS,
            DEFAULT_ADMIN_ADDRESS,
            "CMTA Token",
            "CMTAT",
            "CMTAT_ISIN",
            "https://cmta.ch",
            IRuleEngine(address(0)),
            "CMTAT_info",
            FLAG
        );
        // Mint tokens to test the transfer
        vm.prank(DEFAULT_ADMIN_ADDRESS);
        CMTAT_CONTRACT.mint(ADDRESS1, 20);
    }

    /**
    The admin is assigned the PAUSER role when the contract is deployed
    */
    function testCanBePausedByAdmin() public {
        // Act
        vm.prank(DEFAULT_ADMIN_ADDRESS);
        vm.expectEmit(false, false, false, true);
        emit Paused(DEFAULT_ADMIN_ADDRESS);
        CMTAT_CONTRACT.pause();
        // Assert
        vm.prank(ADDRESS1);
        vm.expectRevert(bytes("CMTAT: transfer rejected by validation module"));
        CMTAT_CONTRACT.transfer(ADDRESS2, 10);
    }

    function testCanBePausedByANewPauser() public {
        // Arrange
        vm.prank(DEFAULT_ADMIN_ADDRESS);
        CMTAT_CONTRACT.grantRole(PAUSER_ROLE, ADDRESS1);

        // Assert
        vm.expectEmit(false, false, false, true);
        emit Paused(ADDRESS1);

        // Act
        vm.prank(ADDRESS1);
        CMTAT_CONTRACT.pause();

        // Assert
        vm.prank(ADDRESS1);
        vm.expectRevert(bytes("CMTAT: transfer rejected by validation module"));
        CMTAT_CONTRACT.transfer(ADDRESS2, 10);
    }

    function testCannotBePausedByNonPauser() public {
        // Assert
        string memory message = string(
            abi.encodePacked(
                "AccessControl: account ",
                vm.toString(ADDRESS1),
                " is missing role ",
                PAUSER_ROLE_HASH
            )
        );
        vm.expectRevert(bytes(message));
        // Act
        vm.prank(ADDRESS1);
        CMTAT_CONTRACT.pause();
    }

    function testCanBeUnpausedByAdmin() public {
        // Arrange
        vm.prank(DEFAULT_ADMIN_ADDRESS);
        CMTAT_CONTRACT.pause();

        // Assert
        vm.expectEmit(false, false, false, true);
        emit Unpaused(DEFAULT_ADMIN_ADDRESS);

        // Act
        vm.prank(DEFAULT_ADMIN_ADDRESS);
        CMTAT_CONTRACT.unpause();

        // Assert
        vm.prank(ADDRESS1);
        // Transfer works
        CMTAT_CONTRACT.transfer(ADDRESS2, 10);
    }

    function testCanBeUnpausedByANewPauser() public {
        // Arrange
        vm.prank(DEFAULT_ADMIN_ADDRESS);
        CMTAT_CONTRACT.pause();
        vm.prank(DEFAULT_ADMIN_ADDRESS);
        CMTAT_CONTRACT.grantRole(PAUSER_ROLE, ADDRESS1);

        // Assert
        vm.expectEmit(false, false, false, true);
        emit Unpaused(ADDRESS1);
        
        // Act
        vm.prank(ADDRESS1);
        CMTAT_CONTRACT.unpause();

        // Assert
        vm.prank(ADDRESS1);
        // Transfer works
        CMTAT_CONTRACT.transfer(ADDRESS2, 10);
    }

    function testCannotBeUnpausedByNonPauser() public {
        // Arrange
        vm.prank(DEFAULT_ADMIN_ADDRESS);
        CMTAT_CONTRACT.pause();
        // Assert
        string memory message = string(
            abi.encodePacked(
                "AccessControl: account ",
                vm.toString(ADDRESS1),
                " is missing role ",
                PAUSER_ROLE_HASH
            )
        );
        vm.expectRevert(bytes(message));
        // Act
        vm.prank(ADDRESS1);
        CMTAT_CONTRACT.unpause();
    }

    // reverts if address1 transfers tokens to address2 when paused
    function testCannotTransferTokenWhenPaused_A() public {
        // Act
        vm.prank(DEFAULT_ADMIN_ADDRESS);
        CMTAT_CONTRACT.pause();

        // Assert
        uint8 res1 = CMTAT_CONTRACT.detectTransferRestriction(
            ADDRESS1,
            ADDRESS2,
            10
        );
        assertEq(res1, 1);

        string memory res2 = CMTAT_CONTRACT.messageForTransferRestriction(1);
        assertEq(res2, "All transfers paused");

        vm.prank(ADDRESS1);
        vm.expectRevert(bytes("CMTAT: transfer rejected by validation module"));
        CMTAT_CONTRACT.transfer(ADDRESS2, 10);
    }

    // reverts if address3 transfers tokens from address1 to address2 when paused
    function testCannotTransferTokenWhenPaused_B() public {
        // Arrange
        // Define allowance
        vm.prank(ADDRESS1);
        CMTAT_CONTRACT.approve(ADDRESS3, 20);

        // Act
        vm.prank(DEFAULT_ADMIN_ADDRESS);
        CMTAT_CONTRACT.pause();

        // Assert
        uint8 res1 = CMTAT_CONTRACT.detectTransferRestriction(
            ADDRESS1,
            ADDRESS2,
            10
        );
        assertEq(res1, 1);

        string memory res2 = CMTAT_CONTRACT.messageForTransferRestriction(1);
        assertEq(res2, "All transfers paused");

        vm.prank(ADDRESS3);
        vm.expectRevert(bytes("CMTAT: transfer rejected by validation module"));
        CMTAT_CONTRACT.transferFrom(ADDRESS1, ADDRESS2, 10);
    }
}
