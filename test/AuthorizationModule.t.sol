//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "./HelperContract.sol";


contract AuthorizationModuleTest is
    Test,
    HelperContract,
    AuthorizationModule,
    PauseModule
{
    bool resBool;
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
    }

    function testAdminCanGrantRole() public {
        // Act
        vm.expectEmit(true, true, false, true);
        emit RoleGranted(PAUSER_ROLE, ADDRESS1, DEFAULT_ADMIN_ADDRESS);
        vm.prank(DEFAULT_ADMIN_ADDRESS);
        CMTAT_CONTRACT.grantRole(PAUSER_ROLE, ADDRESS1);
        // Assert
        resBool = CMTAT_CONTRACT.hasRole(PAUSER_ROLE, ADDRESS1);
        assertEq(resBool, true);
    }

    function testAdminCanRevokeRole() public {
        // Arrange
        vm.prank(DEFAULT_ADMIN_ADDRESS);
        CMTAT_CONTRACT.grantRole(PAUSER_ROLE, ADDRESS1);
        // Arrange - Assert
        resBool = CMTAT_CONTRACT.hasRole(PAUSER_ROLE, ADDRESS1);
        assertEq(resBool, true);
        // Act
        vm.prank(DEFAULT_ADMIN_ADDRESS);
        vm.expectEmit(true, true, false, true);
        emit RoleRevoked(PAUSER_ROLE, ADDRESS1, DEFAULT_ADMIN_ADDRESS);
        CMTAT_CONTRACT.revokeRole(PAUSER_ROLE, ADDRESS1);
        // Assert
        resBool = CMTAT_CONTRACT.hasRole(PAUSER_ROLE, ADDRESS1);
        assertFalse(resBool);
    }

    function testCannotNonAdminGrantRole() public {
        // Arrange - Assert
        resBool = CMTAT_CONTRACT.hasRole(PAUSER_ROLE, ADDRESS1);
        assertFalse(resBool);
        // Act
        string memory message = string(
            abi.encodePacked(
                "AccessControl: account ",
                vm.toString(ADDRESS2),
                " is missing role ",
                DEFAULT_ADMIN_ROLE_HASH
            )
        );
        vm.expectRevert(bytes(message));
        vm.prank(ADDRESS2);
        CMTAT_CONTRACT.grantRole(PAUSER_ROLE, ADDRESS1);
        // Assert
        resBool = CMTAT_CONTRACT.hasRole(PAUSER_ROLE, ADDRESS1);
        assertFalse(resBool);
    }

    function testCannotNonAdminRevokeRole() public {
        // Arrange
        resBool = CMTAT_CONTRACT.hasRole(PAUSER_ROLE, ADDRESS1);
        assertFalse(resBool);
        vm.prank(DEFAULT_ADMIN_ADDRESS);
        CMTAT_CONTRACT.grantRole(PAUSER_ROLE, ADDRESS1);
        // Arrange - Assert
        resBool = CMTAT_CONTRACT.hasRole(PAUSER_ROLE, ADDRESS1);
        assertEq(resBool, true);
        // Act
        vm.prank(ADDRESS2);
        string memory message = string(
            abi.encodePacked(
                "AccessControl: account ",
                vm.toString(ADDRESS2),
                " is missing role ",
                DEFAULT_ADMIN_ROLE_HASH
            )
        );
        vm.expectRevert(bytes(message));
        CMTAT_CONTRACT.revokeRole(PAUSER_ROLE, ADDRESS1);
        // assert
        resBool = CMTAT_CONTRACT.hasRole(PAUSER_ROLE, ADDRESS1);
        assertEq(resBool, true);
    }
}
