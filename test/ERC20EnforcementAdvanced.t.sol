//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import "./HelperContract.sol";

contract ERC20EnforcementAdvancedTest is HelperContract {
    bytes32 public constant ERC20ENFORCER_ROLE = keccak256("ERC20ENFORCER_ROLE");

    // declared in ERC20EnforcementModuleInternal
    error CMTAT_ERC20EnforcementModule_ValueExceedsAvailableBalance();
    error CMTAT_ERC20EnforcementModule_ValueExceedsFrozenBalance();
    error CMTAT_ERC20EnforcementModule_ValueEqualCurrentFrozenTokens();

    event TokensFrozen(address indexed account, uint256 value, bytes data);
    event TokensUnfrozen(address indexed account, uint256 value, bytes data);
    event Enforcement(address indexed enforcer, address indexed account, uint256 amount, bytes data);

    function setUp() public {
        _deployToken();
        vm.startPrank(ADMIN);
        cmtat.mint(USER1, 1_000);
        cmtat.grantRole(ERC20ENFORCER_ROLE, USER2);
        vm.stopPrank();
    }

    function test_ERC20EnforcerCanFreezePartialTokens() public {
        vm.prank(USER2);
        vm.expectEmit(true, false, false, true);
        emit TokensFrozen(USER1, 400, "");
        cmtat.freezePartialTokens(USER1, 400);

        assertEq(cmtat.getFrozenTokens(USER1), 400);
        assertEq(cmtat.getActiveBalanceOf(USER1), 600);
    }

    function test_RevertWhen_FreezePartialExceedsBalance() public {
        vm.prank(USER2);
        vm.expectRevert();
        cmtat.freezePartialTokens(USER1, 1_001);
    }

    function test_RevertWhen_NonERC20EnforcerFreezes() public {
        vm.prank(USER3);
        vm.expectRevert();
        cmtat.freezePartialTokens(USER1, 1);
    }

    function test_ForcedTransferUnfreezesAsNeeded() public {
        vm.prank(USER2);
        cmtat.freezePartialTokens(USER1, 700);
        assertEq(cmtat.getActiveBalanceOf(USER1), 300);

        vm.prank(ADMIN);
        vm.expectEmit(true, false, false, true);
        emit TokensUnfrozen(USER1, 200, "");
        vm.expectEmit(true, true, false, true);
        emit Enforcement(ADMIN, USER1, 500, "");
        assertTrue(cmtat.forcedTransfer(USER1, USER3, 500));

        assertEq(cmtat.balanceOf(USER1), 500);
        assertEq(cmtat.balanceOf(USER3), 500);
        assertEq(cmtat.getFrozenTokens(USER1), 500);
        assertEq(cmtat.getActiveBalanceOf(USER1), 0);
    }

    function test_ForcedTransferToZeroBurnsTokens() public {
        uint256 supplyBefore = cmtat.totalSupply();

        vm.prank(ADMIN);
        assertTrue(cmtat.forcedTransfer(USER1, ZERO_ADDRESS, 250));

        assertEq(cmtat.balanceOf(USER1), 750);
        assertEq(cmtat.totalSupply(), supplyBefore - 250);
    }

    function test_RevertWhen_NonAdminForcedTransfer() public {
        vm.prank(USER2);
        vm.expectRevert();
        cmtat.forcedTransfer(USER1, USER3, 1);
    }

    // ============ Forced Transfer — Bypasses ============

    /// @dev Enforcement is deliberately not routed through the transfer validation: the issuer must
    ///      keep the ability to seize tokens while the token is paused.
    function test_ForcedTransferWorksWhilePaused() public {
        vm.startPrank(ADMIN);
        cmtat.pause();
        assertTrue(cmtat.forcedTransfer(USER1, USER3, 100));
        vm.stopPrank();

        assertEq(cmtat.balanceOf(USER3), 100);
        // a normal transfer stays blocked
        vm.prank(USER1);
        vm.expectRevert();
        cmtat.transfer(USER3, 1);
    }

    function test_ForcedTransferWorksFromAndToFrozenAddress() public {
        vm.startPrank(ADMIN);
        cmtat.setAddressFrozen(USER1, true);
        cmtat.setAddressFrozen(USER3, true);

        assertTrue(cmtat.forcedTransfer(USER1, USER3, 100));
        vm.stopPrank();

        assertEq(cmtat.balanceOf(USER1), 900);
        assertEq(cmtat.balanceOf(USER3), 100);
    }

    // ============ Forced Transfer — Allowance Side Effect ============

    /// @dev ERC-3643 semantics: a forced transfer consumes any finite allowance the holder had
    ///      granted to the *recipient*, so the recipient cannot pull the same tokens twice.
    function test_ForcedTransferReducesRecipientAllowance() public {
        vm.prank(USER1);
        cmtat.approve(USER3, 400);

        vm.prank(ADMIN);
        cmtat.forcedTransfer(USER1, USER3, 250);

        assertEq(cmtat.allowance(USER1, USER3), 150);
    }

    function test_ForcedTransferZeroesAnAllowanceSmallerThanTheAmount() public {
        vm.prank(USER1);
        cmtat.approve(USER3, 100);

        vm.prank(ADMIN);
        cmtat.forcedTransfer(USER1, USER3, 250);

        assertEq(cmtat.allowance(USER1, USER3), 0);
    }

    function test_ForcedTransferLeavesInfiniteAllowanceUntouched() public {
        vm.prank(USER1);
        cmtat.approve(USER3, type(uint256).max);

        vm.prank(ADMIN);
        cmtat.forcedTransfer(USER1, USER3, 250);

        assertEq(cmtat.allowance(USER1, USER3), type(uint256).max);
    }

    // ============ Partial Freeze Arithmetic ============

    function test_FreezePartialTokensAccumulate() public {
        vm.startPrank(USER2);
        cmtat.freezePartialTokens(USER1, 300);
        cmtat.freezePartialTokens(USER1, 200);
        vm.stopPrank();

        assertEq(cmtat.getFrozenTokens(USER1), 500);
        assertEq(cmtat.getActiveBalanceOf(USER1), 500);
    }

    function test_RevertWhen_AccumulatedFreezeExceedsBalance() public {
        vm.startPrank(USER2);
        cmtat.freezePartialTokens(USER1, 600);

        // 600 + 500 > balance of 1_000
        vm.expectRevert(CMTAT_ERC20EnforcementModule_ValueExceedsAvailableBalance.selector);
        cmtat.freezePartialTokens(USER1, 500);
        vm.stopPrank();
    }

    function test_UnfreezePartialTokensReducesTheFrozenAmount() public {
        vm.startPrank(USER2);
        cmtat.freezePartialTokens(USER1, 400);

        vm.expectEmit(true, false, false, true);
        emit TokensUnfrozen(USER1, 150, "");
        cmtat.unfreezePartialTokens(USER1, 150);
        vm.stopPrank();

        assertEq(cmtat.getFrozenTokens(USER1), 250);
        assertEq(cmtat.getActiveBalanceOf(USER1), 750);
    }

    function test_RevertWhen_UnfreezeExceedsFrozenBalance() public {
        vm.startPrank(USER2);
        cmtat.freezePartialTokens(USER1, 400);

        vm.expectRevert(CMTAT_ERC20EnforcementModule_ValueExceedsFrozenBalance.selector);
        cmtat.unfreezePartialTokens(USER1, 401);
        vm.stopPrank();
    }

    /// @dev `setFrozenTokens` overwrites (approve-like) instead of adding, and picks the freeze or
    ///      the unfreeze event depending on the direction of the change.
    function test_SetFrozenTokensOverwritesInBothDirections() public {
        vm.startPrank(USER2);
        cmtat.freezePartialTokens(USER1, 400);

        vm.expectEmit(true, false, false, true);
        emit TokensFrozen(USER1, 200, "");
        assertTrue(cmtat.setFrozenTokens(USER1, 600));
        assertEq(cmtat.getFrozenTokens(USER1), 600);

        vm.expectEmit(true, false, false, true);
        emit TokensUnfrozen(USER1, 500, "");
        assertTrue(cmtat.setFrozenTokens(USER1, 100));
        vm.stopPrank();

        assertEq(cmtat.getFrozenTokens(USER1), 100);
        assertEq(cmtat.getActiveBalanceOf(USER1), 900);
    }

    function test_RevertWhen_SetFrozenTokensToTheCurrentValue() public {
        vm.startPrank(USER2);
        cmtat.freezePartialTokens(USER1, 400);

        vm.expectRevert(CMTAT_ERC20EnforcementModule_ValueEqualCurrentFrozenTokens.selector);
        cmtat.setFrozenTokens(USER1, 400);
        vm.stopPrank();
    }

    function test_FrozenTokensBlockOnlyTheFrozenPartOfATransfer() public {
        vm.prank(USER2);
        cmtat.freezePartialTokens(USER1, 700);

        vm.prank(USER1);
        cmtat.transfer(USER3, 300);
        assertEq(cmtat.balanceOf(USER3), 300);

        // the remaining 700 are frozen
        vm.prank(USER1);
        vm.expectRevert();
        cmtat.transfer(USER3, 1);
    }
}
