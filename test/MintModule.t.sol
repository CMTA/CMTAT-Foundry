//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "./HelperContract.sol";

contract MintModuleTest is Test, HelperContract, MintModule {
    function setUp() public {
        vm.prank(ADMIN_ADDRESS);
        CMTAT_CONTRACT = new CMTAT(ZERO_ADDRESS, false,
            ADMIN_ADDRESS,
            "CMTA Token",
            "CMTAT",
            "CMTAT_ISIN",
            "https://cmta.ch");
    }

    /**
    The admin is assigned the MINTER role when the contract is deployed
     */
    function testCanBeMintedByAdmin() public {
        // Arrange - Assert
        // Check first balance
        uint256 res1 = CMTAT_CONTRACT.balanceOf(ADMIN_ADDRESS);
        assertEq(res1, 0);

        // Act
        // Issue 20 and check balances and total supply
        vm.prank(ADMIN_ADDRESS);
        vm.expectEmit(true, true, false, true);
        emit Transfer(ZERO_ADDRESS, ADDRESS1, 20);
        vm.expectEmit(true, false, false, true);
        emit Mint(ADDRESS1, 20);
        CMTAT_CONTRACT.mint(ADDRESS1, 20);

        // Assert
        uint256 res2 = CMTAT_CONTRACT.balanceOf(ADDRESS1);
        assertEq(res2, 20);

        uint256 res3 = CMTAT_CONTRACT.totalSupply();
        assertEq(res3, 20);

       
        // Issue 50 and check intermediate balances and total supply
        // Assert
        vm.expectEmit(true, true, false, true);
        emit Transfer(ZERO_ADDRESS, ADDRESS2, 50);
        vm.expectEmit(true, false, false, true);
        emit Mint(ADDRESS2, 50);
        
        // Act
        vm.prank(ADMIN_ADDRESS);
        CMTAT_CONTRACT.mint(ADDRESS2, 50);

        // Assert
        uint256 res4 = CMTAT_CONTRACT.balanceOf(ADDRESS2);
        assertEq(res4, 50);

        uint256 res5 = CMTAT_CONTRACT.totalSupply();
        assertEq(res5, 70);
    }

    function testCanBeMintedByANewMinter() public {
        // Arrange
        vm.prank(ADMIN_ADDRESS);
        CMTAT_CONTRACT.grantRole(MINTER_ROLE, ADDRESS1);
        // Arrange - Assert
        // Check first balance
        uint256 res1 = CMTAT_CONTRACT.balanceOf(ADMIN_ADDRESS);
        assertEq(res1, 0);

        // Issue 20
        // Assert
        vm.expectEmit(true, true, false, true);
        emit Transfer(ZERO_ADDRESS, ADDRESS1, 20);
        emit Mint(ADDRESS1, 20);

        // Act
        vm.prank(ADDRESS1);
        CMTAT_CONTRACT.mint(ADDRESS1, 20);

        // Assert
        // Check balances and total supply
        uint256 res2 = CMTAT_CONTRACT.balanceOf(ADDRESS1);
        assertEq(res2, 20);

        uint256 res3 = CMTAT_CONTRACT.totalSupply();
        assertEq(res3, 20);
    }

    // reverts when issuing by a non minter
    function testCannotIssuingByNonMinter() public {
        // Assert
        string memory message = string(
            abi.encodePacked(
                "AccessControl: account ",
                vm.toString(ADDRESS1),
                " is missing role ",
                MINTER_ROLE_HASH
            )
        );
        vm.expectRevert(bytes(message));
        // Act
        vm.prank(ADDRESS1);
        CMTAT_CONTRACT.mint(ADDRESS1, 20);
    }
}
