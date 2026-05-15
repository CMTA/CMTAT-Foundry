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
}
