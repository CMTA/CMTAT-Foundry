//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import "./HelperContract.sol";

contract FreezeModuleTest is HelperContract {
    uint256 constant INITIAL_SUPPLY = 1000;

    // Events from IERC3643EnforcementEvent
    event AddressFrozen(address indexed account, bool indexed isFrozen, address indexed enforcer, bytes data);

    function setUp() public {
        _deployToken();
        // Mint initial tokens to USER1
        vm.prank(ADMIN);
        cmtat.mint(USER1, INITIAL_SUPPLY);
    }

    // ============ Basic Freeze Tests ============

    function test_AdminCanFreezeAddress() public {
        // Verify initial state - not frozen
        assertFalse(cmtat.isFrozen(USER1));

        // Admin freezes USER1
        vm.prank(ADMIN);
        vm.expectEmit(true, true, true, true);
        emit AddressFrozen(USER1, true, ADMIN, "");
        cmtat.setAddressFrozen(USER1, true);

        // Verify USER1 is now frozen
        assertTrue(cmtat.isFrozen(USER1));
    }

    function test_AdminCanUnfreezeAddress() public {
        // First freeze USER1
        vm.prank(ADMIN);
        cmtat.setAddressFrozen(USER1, true);
        assertTrue(cmtat.isFrozen(USER1));

        // Now unfreeze
        vm.prank(ADMIN);
        vm.expectEmit(true, true, true, true);
        emit AddressFrozen(USER1, false, ADMIN, "");
        cmtat.setAddressFrozen(USER1, false);

        // Verify USER1 is unfrozen
        assertFalse(cmtat.isFrozen(USER1));
    }

    function test_FreezeWithData() public {
        bytes memory reason = "compliance violation";

        vm.prank(ADMIN);
        vm.expectEmit(true, true, true, true);
        emit AddressFrozen(USER1, true, ADMIN, reason);
        cmtat.setAddressFrozen(USER1, true, reason);

        assertTrue(cmtat.isFrozen(USER1));
    }

    function test_UnfreezeWithData() public {
        // First freeze
        vm.prank(ADMIN);
        cmtat.setAddressFrozen(USER1, true);

        bytes memory reason = "compliance resolved";

        vm.prank(ADMIN);
        vm.expectEmit(true, true, true, true);
        emit AddressFrozen(USER1, false, ADMIN, reason);
        cmtat.setAddressFrozen(USER1, false, reason);

        assertFalse(cmtat.isFrozen(USER1));
    }

    // ============ Role-based Access Tests ============

    function test_EnforcerRoleCanFreeze() public {
        // Grant ENFORCER_ROLE to USER2
        vm.prank(ADMIN);
        cmtat.grantRole(ENFORCER_ROLE, USER2);

        // USER2 can freeze USER1
        vm.prank(USER2);
        cmtat.setAddressFrozen(USER1, true);

        assertTrue(cmtat.isFrozen(USER1));
    }

    function test_EnforcerRoleCanUnfreeze() public {
        // Grant ENFORCER_ROLE to USER2
        vm.prank(ADMIN);
        cmtat.grantRole(ENFORCER_ROLE, USER2);

        // First freeze USER1
        vm.prank(ADMIN);
        cmtat.setAddressFrozen(USER1, true);

        // USER2 unfreezes USER1
        vm.prank(USER2);
        cmtat.setAddressFrozen(USER1, false);

        assertFalse(cmtat.isFrozen(USER1));
    }

    function test_RevertWhen_NonEnforcerTriesToFreeze() public {
        // USER2 does not have enforcer role
        vm.prank(USER2);
        vm.expectRevert();
        cmtat.setAddressFrozen(USER1, true);
    }

    function test_RevertWhen_NonEnforcerTriesToUnfreeze() public {
        // First freeze USER1 as admin
        vm.prank(ADMIN);
        cmtat.setAddressFrozen(USER1, true);

        // USER2 cannot unfreeze
        vm.prank(USER2);
        vm.expectRevert();
        cmtat.setAddressFrozen(USER1, false);
    }

    function test_RevokedEnforcerCannotFreeze() public {
        // Grant and then revoke ENFORCER_ROLE
        vm.prank(ADMIN);
        cmtat.grantRole(ENFORCER_ROLE, USER2);

        vm.prank(ADMIN);
        cmtat.revokeRole(ENFORCER_ROLE, USER2);

        // USER2 can no longer freeze
        vm.prank(USER2);
        vm.expectRevert();
        cmtat.setAddressFrozen(USER1, true);
    }

    // ============ Transfer Restriction Tests ============

    function test_FrozenAddressCannotTransfer() public {
        // Freeze USER1
        vm.prank(ADMIN);
        cmtat.setAddressFrozen(USER1, true);

        // USER1 cannot transfer tokens
        vm.prank(USER1);
        vm.expectRevert();
        cmtat.transfer(USER2, 100);
    }

    function test_CannotTransferToFrozenAddress() public {
        // Give USER2 some tokens
        vm.prank(ADMIN);
        cmtat.mint(USER2, 500);

        // Freeze USER1
        vm.prank(ADMIN);
        cmtat.setAddressFrozen(USER1, true);

        // USER2 cannot transfer to frozen USER1
        vm.prank(USER2);
        vm.expectRevert();
        cmtat.transfer(USER1, 100);
    }

    function test_UnfrozenAddressCanTransfer() public {
        // Freeze then unfreeze USER1
        vm.prank(ADMIN);
        cmtat.setAddressFrozen(USER1, true);

        vm.prank(ADMIN);
        cmtat.setAddressFrozen(USER1, false);

        // USER1 can transfer again
        vm.prank(USER1);
        bool success = cmtat.transfer(USER2, 100);
        assertTrue(success);
        assertEq(cmtat.balanceOf(USER2), 100);
    }

    // ============ Batch Freeze Tests ============

    function test_BatchFreeze() public {
        address[] memory accounts = new address[](3);
        accounts[0] = USER1;
        accounts[1] = USER2;
        accounts[2] = USER3;

        bool[] memory freezes = new bool[](3);
        freezes[0] = true;
        freezes[1] = true;
        freezes[2] = true;

        vm.prank(ADMIN);
        cmtat.batchSetAddressFrozen(accounts, freezes);

        assertTrue(cmtat.isFrozen(USER1));
        assertTrue(cmtat.isFrozen(USER2));
        assertTrue(cmtat.isFrozen(USER3));
    }

    function test_BatchUnfreeze() public {
        // First freeze all addresses
        address[] memory accounts = new address[](3);
        accounts[0] = USER1;
        accounts[1] = USER2;
        accounts[2] = USER3;

        bool[] memory freezes = new bool[](3);
        freezes[0] = true;
        freezes[1] = true;
        freezes[2] = true;

        vm.prank(ADMIN);
        cmtat.batchSetAddressFrozen(accounts, freezes);

        // Now unfreeze all
        bool[] memory unfreezes = new bool[](3);
        unfreezes[0] = false;
        unfreezes[1] = false;
        unfreezes[2] = false;

        vm.prank(ADMIN);
        cmtat.batchSetAddressFrozen(accounts, unfreezes);

        assertFalse(cmtat.isFrozen(USER1));
        assertFalse(cmtat.isFrozen(USER2));
        assertFalse(cmtat.isFrozen(USER3));
    }

    function test_BatchMixedFreezeUnfreeze() public {
        // First freeze USER1
        vm.prank(ADMIN);
        cmtat.setAddressFrozen(USER1, true);

        address[] memory accounts = new address[](2);
        accounts[0] = USER1; // currently frozen
        accounts[1] = USER2; // currently not frozen

        bool[] memory freezes = new bool[](2);
        freezes[0] = false; // unfreeze USER1
        freezes[1] = true; // freeze USER2

        vm.prank(ADMIN);
        cmtat.batchSetAddressFrozen(accounts, freezes);

        assertFalse(cmtat.isFrozen(USER1));
        assertTrue(cmtat.isFrozen(USER2));
    }

    function test_RevertWhen_NonEnforcerTriesBatchFreeze() public {
        address[] memory accounts = new address[](2);
        accounts[0] = USER1;
        accounts[1] = USER2;

        bool[] memory freezes = new bool[](2);
        freezes[0] = true;
        freezes[1] = true;

        vm.prank(USER3);
        vm.expectRevert();
        cmtat.batchSetAddressFrozen(accounts, freezes);
    }

    // ============ Edge Cases ============

    function test_FreezeAlreadyFrozenAddress() public {
        // Freeze USER1
        vm.prank(ADMIN);
        cmtat.setAddressFrozen(USER1, true);

        // Freeze again (should not revert)
        vm.prank(ADMIN);
        cmtat.setAddressFrozen(USER1, true);

        assertTrue(cmtat.isFrozen(USER1));
    }

    function test_UnfreezeAlreadyUnfrozenAddress() public {
        // USER1 is not frozen initially
        assertFalse(cmtat.isFrozen(USER1));

        // Unfreeze (should not revert)
        vm.prank(ADMIN);
        cmtat.setAddressFrozen(USER1, false);

        assertFalse(cmtat.isFrozen(USER1));
    }

    function test_IsFrozenReturnsFalseForNewAddress() public {
        // New address should not be frozen
        address newAddress = address(100);
        assertFalse(cmtat.isFrozen(newAddress));
    }
}
