//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "CMTAT/modules/EnforcementModule.sol";
import "CMTAT/modules/PauseModule.sol";
import "CMTAT/modules/AuthorizationModule.sol";
import "./HelperContract.sol";

contract EnforcementAuthorizationModule is
    Test,
    HelperContract,
    EnforcementModule,
    PauseModule,
    AuthorizationModule
{
    bool resBool;

    function setUp() public {
        vm.prank(OWNER);
        CMTAT_CONTRACT = new CMTAT(ZERO_ADDRESS);
        CMTAT_CONTRACT.initialize(
            OWNER,
            "CMTA Token",
            "CMTAT",
            "CMTAT_ISIN",
            "https://cmta.ch"
        );
        vm.prank(OWNER);
        CMTAT_CONTRACT.mint(ADDRESS1, 50);
    }

    /**
    The admin is assigned the ENFORCER role when the contract is deployed
     */
    function testAdminCanFreezeAddress() public {
        // Arrange - Assert
        resBool = CMTAT_CONTRACT.frozen(ADDRESS1);
        assertFalse(resBool);
        // Act
        vm.expectEmit(true, true,false, false);
        emit Freeze(OWNER, ADDRESS1);
        vm.prank(OWNER);
        CMTAT_CONTRACT.freeze(ADDRESS1);
        // Assert
        resBool = CMTAT_CONTRACT.frozen(ADDRESS1);
        assertEq(resBool, true);
    }

    function testEnforcerRoleCanFreezeAddress() public {
        // Arrange
        vm.prank(OWNER);
        CMTAT_CONTRACT.grantRole(ENFORCER_ROLE, ADDRESS2);
        // Arrange - Assert
        resBool = CMTAT_CONTRACT.frozen(ADDRESS1);
        assertFalse(resBool);
        // Act
        vm.expectEmit(true, true,false, false);
        emit Freeze(ADDRESS2, ADDRESS1);
        vm.prank(ADDRESS2);
        CMTAT_CONTRACT.freeze(ADDRESS1);
        // Assert
        resBool = CMTAT_CONTRACT.frozen(ADDRESS1);
        assertEq(resBool, true);
    }

    function testAdminCanUnfreezeAddress() public {
        // Arrange
        vm.prank(OWNER);
        CMTAT_CONTRACT.freeze(ADDRESS1);
        // Arrange - Assert
        resBool = CMTAT_CONTRACT.frozen(ADDRESS1);
        assertEq(resBool, true);
        // Act
        vm.expectEmit(true, true,false, false);
        emit Unfreeze(OWNER, ADDRESS1);
        vm.prank(OWNER);
        CMTAT_CONTRACT.unfreeze(ADDRESS1);
        // Assert
        resBool = CMTAT_CONTRACT.frozen(ADDRESS1);
        assertEq(resBool, false);
    }

    function testEnforcerRoleCanUnfreezeAddress() public {
        // Arrange
        vm.prank(OWNER);
        CMTAT_CONTRACT.freeze(ADDRESS1);
        vm.prank(OWNER);
        CMTAT_CONTRACT.grantRole(ENFORCER_ROLE, ADDRESS2);
        // Arrange - Assert
        resBool = CMTAT_CONTRACT.frozen(ADDRESS1);
        assertEq(resBool, true);
        // Act
        vm.expectEmit(true, true, false, false);
        emit Unfreeze(ADDRESS2, ADDRESS1);
        vm.prank(ADDRESS2);
        CMTAT_CONTRACT.unfreeze(ADDRESS1);
        // Assert
        resBool = CMTAT_CONTRACT.frozen(ADDRESS1);
        assertEq(resBool, false);
    }

    function testCannotNonEnforcerFreezeAddress() public {
        // Act
        string memory message = string(
            abi.encodePacked(
                "AccessControl: account ",
                vm.toString(ADDRESS2),
                " is missing role ",
                ENFORCER_ROLE_HASH
            )
        );
        vm.expectRevert(bytes(message));
        vm.prank(ADDRESS2);
        CMTAT_CONTRACT.freeze(ADDRESS1);
        // Assert
        resBool = CMTAT_CONTRACT.frozen(ADDRESS1);
        assertEq(resBool, false);
    }

    function testCannotNonEnforcerUnfreezeAddress() public {
        // Arrange
        vm.prank(OWNER);
        CMTAT_CONTRACT.freeze(ADDRESS1);
        // Act
        string memory message = string(
            abi.encodePacked(
                "AccessControl: account ",
                vm.toString(ADDRESS2),
                " is missing role ",
                ENFORCER_ROLE_HASH
            )
        );
        vm.expectRevert(bytes(message));
        vm.prank(ADDRESS2);
        CMTAT_CONTRACT.unfreeze(ADDRESS1);
        // Assert
        resBool = CMTAT_CONTRACT.frozen(ADDRESS1);
        assertEq(resBool, true);
    }
}
