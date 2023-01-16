//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "./HelperContract.sol";

contract EnforcementAuthorizationModule is
    Test,
    HelperContract,
    EnforcementModule,
    PauseModule
{
    bool resBool;
    string constant reasonFreeze = 'testFreeze';
    string constant reasonUnfreeze = 'testUnfreeze';

    function setUp() public {
        vm.prank(ADMIN_ADDRESS);
        CMTAT_CONTRACT = new CMTAT(ZERO_ADDRESS, false,
            ADMIN_ADDRESS,
            "CMTA Token",
            "CMTAT",
            "CMTAT_ISIN",
            "https://cmta.ch");
        vm.prank(ADMIN_ADDRESS);
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
        vm.expectEmit(true, true, true, true);
        emit Freeze(ADMIN_ADDRESS, ADDRESS1, reasonFreeze, reasonFreeze);
        vm.prank(ADMIN_ADDRESS);
        CMTAT_CONTRACT.freeze(ADDRESS1, reasonFreeze);
        // Assert
        resBool = CMTAT_CONTRACT.frozen(ADDRESS1);
        assertEq(resBool, true);
    }

    function testEnforcerRoleCanFreezeAddress() public {
        // Arrange
        vm.prank(ADMIN_ADDRESS);
        CMTAT_CONTRACT.grantRole(ENFORCER_ROLE, ADDRESS2);
        // Arrange - Assert
        resBool = CMTAT_CONTRACT.frozen(ADDRESS1);
        assertFalse(resBool);
        // Act
        vm.expectEmit(true, true, true, true);
        emit Freeze(ADDRESS2, ADDRESS1, reasonFreeze, reasonFreeze);
        vm.prank(ADDRESS2);
        CMTAT_CONTRACT.freeze(ADDRESS1, reasonFreeze);
        // Assert
        resBool = CMTAT_CONTRACT.frozen(ADDRESS1);
        assertEq(resBool, true);
    }

    function testAdminCanUnfreezeAddress() public {
        // Arrange
        vm.prank(ADMIN_ADDRESS);
        CMTAT_CONTRACT.freeze(ADDRESS1, reasonFreeze);
        // Arrange - Assert
        resBool = CMTAT_CONTRACT.frozen(ADDRESS1);
        assertEq(resBool, true);
        // Act
        vm.expectEmit(true, true, true, true);
        emit Unfreeze(ADMIN_ADDRESS, ADDRESS1, reasonUnfreeze, reasonUnfreeze );
        vm.prank(ADMIN_ADDRESS);
        CMTAT_CONTRACT.unfreeze(ADDRESS1, reasonUnfreeze);
        // Assert
        resBool = CMTAT_CONTRACT.frozen(ADDRESS1);
        assertEq(resBool, false);
    }

    function testEnforcerRoleCanUnfreezeAddress() public {
        // Arrange
        vm.prank(ADMIN_ADDRESS);
        CMTAT_CONTRACT.freeze(ADDRESS1, reasonFreeze);
        vm.prank(ADMIN_ADDRESS);
        CMTAT_CONTRACT.grantRole(ENFORCER_ROLE, ADDRESS2);
        // Arrange - Assert
        resBool = CMTAT_CONTRACT.frozen(ADDRESS1);
        assertEq(resBool, true);
        // Act
        vm.expectEmit(true, true, true, true);
        emit Unfreeze(ADDRESS2, ADDRESS1, reasonUnfreeze, reasonUnfreeze);
        vm.prank(ADDRESS2);
        CMTAT_CONTRACT.unfreeze(ADDRESS1, reasonUnfreeze);
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
        CMTAT_CONTRACT.freeze(ADDRESS1, reasonFreeze);
        // Assert
        resBool = CMTAT_CONTRACT.frozen(ADDRESS1);
        assertEq(resBool, false);
    }

    function testCannotNonEnforcerUnfreezeAddress() public {
        // Arrange
        vm.prank(ADMIN_ADDRESS);
        CMTAT_CONTRACT.freeze(ADDRESS1, reasonFreeze);
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
        CMTAT_CONTRACT.unfreeze(ADDRESS1, reasonUnfreeze);
        // Assert
        resBool = CMTAT_CONTRACT.frozen(ADDRESS1);
        assertEq(resBool, true);
    }
}
