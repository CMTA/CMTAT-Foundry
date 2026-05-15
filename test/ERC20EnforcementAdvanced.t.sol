//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import "./HelperContract.sol";

contract ERC20EnforcementAdvancedTest is HelperContract {
    bytes32 public constant ERC20ENFORCER_ROLE = keccak256("ERC20ENFORCER_ROLE");

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
}
