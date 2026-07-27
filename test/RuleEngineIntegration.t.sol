//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import "./HelperContract.sol";
import "./MockRuleEngine.sol";
import "CMTAT/interfaces/engine/IRuleEngine.sol";

contract RuleEngineIntegrationTest is HelperContract {
    error CMTAT_ValidationModule_SameValue();

    MockRuleEngine internal mockRuleEngine;

    function setUp() public {
        _deployToken();
        vm.startPrank(ADMIN);
        cmtat.mint(USER1, 1_000);
        mockRuleEngine = new MockRuleEngine();
        cmtat.setRuleEngine(IRuleEngine(address(mockRuleEngine)));
        vm.stopPrank();
    }

    function test_AdminCanSetRuleEngine() public {
        MockRuleEngine second = new MockRuleEngine();
        vm.prank(ADMIN);
        cmtat.setRuleEngine(IRuleEngine(address(second)));
        assertEq(address(cmtat.ruleEngine()), address(second));
    }

    function test_RevertWhen_NonAdminSetsRuleEngine() public {
        MockRuleEngine second = new MockRuleEngine();
        vm.prank(USER1);
        vm.expectRevert();
        cmtat.setRuleEngine(IRuleEngine(address(second)));
    }

    function test_RevertWhen_SetRuleEngineSameValue() public {
        vm.prank(ADMIN);
        vm.expectRevert(CMTAT_ValidationModule_SameValue.selector);
        cmtat.setRuleEngine(IRuleEngine(address(mockRuleEngine)));
    }

    function test_RevertWhen_RuleEngineRejectsTransfer() public {
        mockRuleEngine.setRevertOnTransferred(true);

        vm.prank(USER1);
        vm.expectRevert(MockRuleEngine.MockRuleEngine_TransferRejected.selector);
        cmtat.transfer(USER2, 100);
    }

    function test_RevertWhen_RuleEngineRejectsTransferFrom() public {
        vm.prank(USER1);
        cmtat.approve(USER2, 200);

        mockRuleEngine.setRevertOnTransferred(true);

        vm.prank(USER2);
        vm.expectRevert(MockRuleEngine.MockRuleEngine_TransferRejected.selector);
        cmtat.transferFrom(USER1, USER3, 100);
    }

    function test_ReadPathReflectsTheRuleEngineVerdict() public {
        assertTrue(cmtat.canTransfer(USER1, USER2, 100));
        assertTrue(cmtat.canTransferFrom(USER3, USER1, USER2, 100));

        mockRuleEngine.setAllowCanTransfer(false);
        mockRuleEngine.setAllowCanTransferFrom(false);

        assertFalse(cmtat.canTransfer(USER1, USER2, 100));
        assertFalse(cmtat.canTransferFrom(USER3, USER1, USER2, 100));
    }

    /// @dev Only the `transferred` hook can stop a transfer: `canTransfer` is a read-only opinion,
    ///      so a rule engine that merely returns false there does **not** block the write path.
    ///      Engines must revert in `transferred` to enforce a rule.
    function test_RuleEngineRejectingOnlyInCanTransferDoesNotBlockTheTransfer() public {
        mockRuleEngine.setAllowCanTransfer(false);
        assertFalse(cmtat.canTransfer(USER1, USER2, 100));

        vm.prank(USER1);
        cmtat.transfer(USER2, 100);
        assertEq(cmtat.balanceOf(USER2), 100);
    }

    function test_ClearingTheRuleEngineRemovesItsRules() public {
        mockRuleEngine.setRevertOnTransferred(true);

        vm.prank(ADMIN);
        cmtat.setRuleEngine(IRuleEngine(ZERO_ADDRESS));
        assertEq(address(cmtat.ruleEngine()), ZERO_ADDRESS);

        vm.prank(USER1);
        cmtat.transfer(USER2, 100);
        assertEq(cmtat.balanceOf(USER2), 100);
    }

    /// @dev The engine's `transferred` hook also runs on mint and burn, so a rejecting engine
    ///      stops issuance and redemption too — not only holder-to-holder transfers.
    function test_RuleEngineAlsoGovernsMintAndBurn() public {
        vm.prank(ADMIN);
        cmtat.mint(USER2, 50);
        assertEq(cmtat.balanceOf(USER2), 50);

        mockRuleEngine.setRevertOnTransferred(true);

        vm.prank(ADMIN);
        vm.expectRevert(MockRuleEngine.MockRuleEngine_TransferRejected.selector);
        cmtat.mint(USER2, 50);

        vm.prank(ADMIN);
        vm.expectRevert(MockRuleEngine.MockRuleEngine_TransferRejected.selector);
        cmtat.burn(USER2, 20, "");

        assertEq(cmtat.balanceOf(USER2), 50);
    }
}
