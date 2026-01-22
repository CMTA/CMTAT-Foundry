//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./HelperContract.sol";

contract MintModuleTest is HelperContract {
    // Events from IERC7551Mint
    event Mint(address indexed minter, address indexed account, uint256 value, bytes data);

    function setUp() public {
        _deployToken();
    }

    // ============ Basic Mint Tests ============

    function test_AdminCanMint() public {
        uint256 mintAmount = 100;

        // Verify initial state
        assertEq(cmtat.balanceOf(USER1), 0);
        assertEq(cmtat.totalSupply(), 0);

        // Admin mints tokens
        vm.prank(ADMIN);
        vm.expectEmit(true, true, false, true);
        emit IERC20.Transfer(ZERO_ADDRESS, USER1, mintAmount);
        vm.expectEmit(true, true, false, true);
        emit Mint(ADMIN, USER1, mintAmount, "");
        cmtat.mint(USER1, mintAmount);

        // Verify results
        assertEq(cmtat.balanceOf(USER1), mintAmount);
        assertEq(cmtat.totalSupply(), mintAmount);
    }

    function test_MintMultipleTimes() public {
        // First mint
        vm.prank(ADMIN);
        cmtat.mint(USER1, 50);
        assertEq(cmtat.balanceOf(USER1), 50);
        assertEq(cmtat.totalSupply(), 50);

        // Second mint to same address
        vm.prank(ADMIN);
        cmtat.mint(USER1, 30);
        assertEq(cmtat.balanceOf(USER1), 80);
        assertEq(cmtat.totalSupply(), 80);

        // Mint to different address
        vm.prank(ADMIN);
        cmtat.mint(USER2, 70);
        assertEq(cmtat.balanceOf(USER2), 70);
        assertEq(cmtat.totalSupply(), 150);
    }

    function test_MintWithData() public {
        uint256 mintAmount = 100;
        bytes memory data = "mint reason";

        vm.prank(ADMIN);
        vm.expectEmit(true, true, false, true);
        emit Mint(ADMIN, USER1, mintAmount, data);
        cmtat.mint(USER1, mintAmount, data);

        assertEq(cmtat.balanceOf(USER1), mintAmount);
    }

    // ============ Role-based Access Tests ============

    function test_MinterRoleCanMint() public {
        // Grant MINTER_ROLE to USER1
        vm.prank(ADMIN);
        cmtat.grantRole(MINTER_ROLE, USER1);

        // USER1 can now mint
        vm.prank(USER1);
        cmtat.mint(USER2, 100);

        assertEq(cmtat.balanceOf(USER2), 100);
    }

    function test_RevertWhen_NonMinterTriesToMint() public {
        // USER1 does not have minter role
        vm.prank(USER1);
        vm.expectRevert();
        cmtat.mint(USER2, 100);
    }

    function test_RevokedMinterCannotMint() public {
        // Grant and then revoke MINTER_ROLE
        vm.prank(ADMIN);
        cmtat.grantRole(MINTER_ROLE, USER1);

        vm.prank(ADMIN);
        cmtat.revokeRole(MINTER_ROLE, USER1);

        // USER1 can no longer mint
        vm.prank(USER1);
        vm.expectRevert();
        cmtat.mint(USER2, 100);
    }

    // ============ Batch Mint Tests ============

    function test_BatchMint() public {
        address[] memory accounts = new address[](3);
        accounts[0] = USER1;
        accounts[1] = USER2;
        accounts[2] = USER3;

        uint256[] memory values = new uint256[](3);
        values[0] = 100;
        values[1] = 200;
        values[2] = 300;

        vm.prank(ADMIN);
        cmtat.batchMint(accounts, values);

        assertEq(cmtat.balanceOf(USER1), 100);
        assertEq(cmtat.balanceOf(USER2), 200);
        assertEq(cmtat.balanceOf(USER3), 300);
        assertEq(cmtat.totalSupply(), 600);
    }

    function test_RevertWhen_NonMinterTriesBatchMint() public {
        address[] memory accounts = new address[](2);
        accounts[0] = USER1;
        accounts[1] = USER2;

        uint256[] memory values = new uint256[](2);
        values[0] = 100;
        values[1] = 200;

        vm.prank(USER1);
        vm.expectRevert();
        cmtat.batchMint(accounts, values);
    }

    // ============ Edge Cases ============

    function test_MintZeroAmount() public {
        vm.prank(ADMIN);
        cmtat.mint(USER1, 0);

        assertEq(cmtat.balanceOf(USER1), 0);
        assertEq(cmtat.totalSupply(), 0);
    }

    function test_RevertWhen_MintToZeroAddress() public {
        vm.prank(ADMIN);
        vm.expectRevert();
        cmtat.mint(ZERO_ADDRESS, 100);
    }
}
