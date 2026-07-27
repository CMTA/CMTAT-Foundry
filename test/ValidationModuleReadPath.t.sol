//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import "./HelperContract.sol";
import "./MockRuleEngine.sol";
import "CMTAT/interfaces/tokenization/draft-IERC1404.sol";
import "CMTAT/interfaces/engine/IRuleEngine.sol";

contract ValidationModuleReadPathTest is HelperContract {
    function setUp() public {
        _deployToken();
        vm.prank(ADMIN);
        cmtat.mint(USER1, 1_000);
    }

    function test_ReadPath_PausedRestrictionCodesAndMessages() public {
        vm.prank(ADMIN);
        cmtat.pause();

        uint8 code = cmtat.detectTransferRestriction(USER1, USER2, 10);
        assertEq(code, uint8(IERC1404Extend.REJECTED_CODE_BASE.TRANSFER_REJECTED_PAUSED));
        assertEq(cmtat.messageForTransferRestriction(code), "EnforcedPause");
        assertFalse(cmtat.canTransfer(USER1, USER2, 10));
        assertFalse(cmtat.canTransferFrom(USER3, USER1, USER2, 10));
    }

    function test_ReadPath_DeactivatedRestrictionCodesAndMessages() public {
        vm.startPrank(ADMIN);
        cmtat.pause();
        cmtat.deactivateContract();
        vm.stopPrank();

        uint8 code = cmtat.detectTransferRestriction(USER1, USER2, 10);
        assertEq(code, uint8(IERC1404Extend.REJECTED_CODE_BASE.TRANSFER_REJECTED_DEACTIVATED));
        assertEq(cmtat.messageForTransferRestriction(code), "ContractDeactivated");
        assertFalse(cmtat.canTransfer(USER1, USER2, 10));
        assertFalse(cmtat.canTransferFrom(USER3, USER1, USER2, 10));
    }

    function test_ReadPath_FrozenFromToAndSpenderCodes() public {
        vm.prank(ADMIN);
        cmtat.setAddressFrozen(USER1, true);
        uint8 fromCode = cmtat.detectTransferRestriction(USER1, USER2, 10);
        assertEq(fromCode, uint8(IERC1404Extend.REJECTED_CODE_BASE.TRANSFER_REJECTED_FROM_FROZEN));
        assertEq(cmtat.messageForTransferRestriction(fromCode), "AddrFromIsFrozen");

        vm.prank(ADMIN);
        cmtat.setAddressFrozen(USER1, false);
        vm.prank(ADMIN);
        cmtat.setAddressFrozen(USER2, true);
        uint8 toCode = cmtat.detectTransferRestriction(USER1, USER2, 10);
        assertEq(toCode, uint8(IERC1404Extend.REJECTED_CODE_BASE.TRANSFER_REJECTED_TO_FROZEN));
        assertEq(cmtat.messageForTransferRestriction(toCode), "AddrToIsFrozen");

        vm.prank(ADMIN);
        cmtat.setAddressFrozen(USER3, true);
        uint8 spenderCode = cmtat.detectTransferRestrictionFrom(USER3, USER1, USER2, 10);
        assertEq(spenderCode, uint8(IERC1404Extend.REJECTED_CODE_BASE.TRANSFER_REJECTED_SPENDER_FROZEN));
        assertEq(cmtat.messageForTransferRestriction(spenderCode), "AddrSpenderIsFrozen");
    }

    function test_ReadPath_InsufficientActiveBalanceCode() public {
        bytes32 ERC20ENFORCER_ROLE = keccak256("ERC20ENFORCER_ROLE");
        vm.startPrank(ADMIN);
        cmtat.grantRole(ERC20ENFORCER_ROLE, ADMIN);
        cmtat.freezePartialTokens(USER1, 900);
        vm.stopPrank();

        uint8 code = cmtat.detectTransferRestriction(USER1, USER2, 200);
        assertEq(code, uint8(IERC1404Extend.REJECTED_CODE_BASE.TRANSFER_REJECTED_FROM_INSUFFICIENT_ACTIVE_BALANCE));
        assertEq(cmtat.messageForTransferRestriction(code), "AddrFrom:insufficientActiveBalance");
        assertFalse(cmtat.canTransfer(USER1, USER2, 200));
    }

    function test_ReadPath_UnknownCodeMessageFallback() public {
        assertEq(cmtat.messageForTransferRestriction(254), "UnknownCode");
    }

    function test_ReadPath_RuleEngineZeroAndNonZeroTransitions() public {
        MockRuleEngine mock = new MockRuleEngine();

        vm.prank(ADMIN);
        cmtat.setRuleEngine(IRuleEngine(address(mock)));
        assertTrue(cmtat.canTransfer(USER1, USER2, 10));

        mock.setAllowCanTransfer(false);
        assertFalse(cmtat.canTransfer(USER1, USER2, 10));

        vm.prank(ADMIN);
        cmtat.setRuleEngine(IRuleEngine(address(0)));
        assertTrue(cmtat.canTransfer(USER1, USER2, 10));
    }
}
