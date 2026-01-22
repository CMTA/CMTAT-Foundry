//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import "./HelperContract.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BurnModuleTest is HelperContract {
    uint256 constant INITIAL_SUPPLY = 1000;

    // Events from IERC7551Burn
    event Burn(address indexed burner, address indexed account, uint256 value, bytes data);

    function setUp() public {
        _deployToken();
        // Mint initial tokens to USER1
        vm.prank(ADMIN);
        cmtat.mint(USER1, INITIAL_SUPPLY);
    }

    // ============ Basic Burn Tests ============

    function test_AdminCanBurn() public {
        uint256 burnAmount = 100;

        // Verify initial state
        assertEq(cmtat.balanceOf(USER1), INITIAL_SUPPLY);

        // Admin burns tokens from USER1
        vm.prank(ADMIN);
        vm.expectEmit(true, true, false, true);
        emit IERC20.Transfer(USER1, ZERO_ADDRESS, burnAmount);
        vm.expectEmit(true, true, false, true);
        emit Burn(ADMIN, USER1, burnAmount, "");
        cmtat.burn(USER1, burnAmount);

        // Verify results
        assertEq(cmtat.balanceOf(USER1), INITIAL_SUPPLY - burnAmount);
        assertEq(cmtat.totalSupply(), INITIAL_SUPPLY - burnAmount);
    }

    function test_BurnMultipleTimes() public {
        // First burn
        vm.prank(ADMIN);
        cmtat.burn(USER1, 200);
        assertEq(cmtat.balanceOf(USER1), 800);
        assertEq(cmtat.totalSupply(), 800);

        // Second burn
        vm.prank(ADMIN);
        cmtat.burn(USER1, 300);
        assertEq(cmtat.balanceOf(USER1), 500);
        assertEq(cmtat.totalSupply(), 500);
    }

    function test_BurnWithData() public {
        uint256 burnAmount = 100;
        bytes memory data = "burn reason";

        vm.prank(ADMIN);
        vm.expectEmit(true, true, false, true);
        emit Burn(ADMIN, USER1, burnAmount, data);
        cmtat.burn(USER1, burnAmount, data);

        assertEq(cmtat.balanceOf(USER1), INITIAL_SUPPLY - burnAmount);
    }

    function test_BurnEntireBalance() public {
        vm.prank(ADMIN);
        cmtat.burn(USER1, INITIAL_SUPPLY);

        assertEq(cmtat.balanceOf(USER1), 0);
        assertEq(cmtat.totalSupply(), 0);
    }

    // ============ Role-based Access Tests ============

    function test_BurnerRoleCanBurn() public {
        // Grant BURNER_ROLE to USER2
        vm.prank(ADMIN);
        cmtat.grantRole(BURNER_ROLE, USER2);

        // USER2 can now burn from USER1
        vm.prank(USER2);
        cmtat.burn(USER1, 100);

        assertEq(cmtat.balanceOf(USER1), INITIAL_SUPPLY - 100);
    }

    function test_RevertWhen_NonBurnerTriesToBurn() public {
        // USER2 does not have burner role
        vm.prank(USER2);
        vm.expectRevert();
        cmtat.burn(USER1, 100);
    }

    function test_RevokedBurnerCannotBurn() public {
        // Grant and then revoke BURNER_ROLE
        vm.prank(ADMIN);
        cmtat.grantRole(BURNER_ROLE, USER2);

        vm.prank(ADMIN);
        cmtat.revokeRole(BURNER_ROLE, USER2);

        // USER2 can no longer burn
        vm.prank(USER2);
        vm.expectRevert();
        cmtat.burn(USER1, 100);
    }

    // ============ Batch Burn Tests ============

    function test_BatchBurn() public {
        // First mint tokens to multiple accounts
        vm.prank(ADMIN);
        cmtat.mint(USER2, 200);
        vm.prank(ADMIN);
        cmtat.mint(USER3, 300);

        address[] memory accounts = new address[](3);
        accounts[0] = USER1;
        accounts[1] = USER2;
        accounts[2] = USER3;

        uint256[] memory values = new uint256[](3);
        values[0] = 100;
        values[1] = 50;
        values[2] = 100;

        uint256 totalSupplyBefore = cmtat.totalSupply();

        vm.prank(ADMIN);
        cmtat.batchBurn(accounts, values);

        assertEq(cmtat.balanceOf(USER1), INITIAL_SUPPLY - 100);
        assertEq(cmtat.balanceOf(USER2), 200 - 50);
        assertEq(cmtat.balanceOf(USER3), 300 - 100);
        assertEq(cmtat.totalSupply(), totalSupplyBefore - 250);
    }

    function test_RevertWhen_NonBurnerTriesBatchBurn() public {
        address[] memory accounts = new address[](1);
        accounts[0] = USER1;

        uint256[] memory values = new uint256[](1);
        values[0] = 100;

        vm.prank(USER2);
        vm.expectRevert();
        cmtat.batchBurn(accounts, values);
    }

    // ============ Edge Cases ============

    function test_BurnZeroAmount() public {
        vm.prank(ADMIN);
        cmtat.burn(USER1, 0);

        assertEq(cmtat.balanceOf(USER1), INITIAL_SUPPLY);
        assertEq(cmtat.totalSupply(), INITIAL_SUPPLY);
    }

    function test_RevertWhen_BurnExceedsBalance() public {
        vm.prank(ADMIN);
        vm.expectRevert();
        cmtat.burn(USER1, INITIAL_SUPPLY + 1);
    }

    function test_RevertWhen_BurnFromAddressWithZeroBalance() public {
        // USER2 has no tokens
        assertEq(cmtat.balanceOf(USER2), 0);

        vm.prank(ADMIN);
        vm.expectRevert();
        cmtat.burn(USER2, 1);
    }
}
