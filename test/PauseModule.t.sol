//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import "./HelperContract.sol";

contract PauseModuleTest is HelperContract {
    bytes32 public constant CROSS_CHAIN_ROLE = keccak256("CROSS_CHAIN_ROLE");
    error CMTAT_PauseModule_ContractIsDeactivated();
    error EnforcedDeactivation();

    function setUp() public {
        _deployToken();
        vm.startPrank(ADMIN);
        cmtat.mint(USER1, 1_000);
        cmtat.grantRole(MINTER_ROLE, USER2);
        cmtat.grantRole(BURNER_ROLE, USER2);
        cmtat.grantRole(CROSS_CHAIN_ROLE, USER2);
        vm.stopPrank();
    }

    function test_PauserCanPauseAndUnpause() public {
        vm.prank(ADMIN);
        cmtat.pause();
        assertTrue(cmtat.paused());

        vm.prank(ADMIN);
        cmtat.unpause();
        assertFalse(cmtat.paused());
    }

    function test_RevertWhen_NonPauserCallsPause() public {
        vm.prank(USER1);
        vm.expectRevert();
        cmtat.pause();
    }

    function test_PausedBlocksApproveTransferAndTransferFrom() public {
        vm.prank(ADMIN);
        cmtat.pause();

        vm.prank(USER1);
        vm.expectRevert();
        cmtat.approve(USER2, 100);

        vm.prank(USER1);
        vm.expectRevert();
        cmtat.transfer(USER2, 100);

        vm.prank(ADMIN);
        cmtat.unpause();
        cmtat.approve(USER2, 100);
        vm.prank(ADMIN);
        cmtat.pause();

        vm.prank(USER2);
        vm.expectRevert();
        cmtat.transferFrom(USER1, USER3, 10);
    }

    function test_PausedBlocksCrosschainOperations() public {
        vm.prank(ADMIN);
        cmtat.pause();

        vm.prank(USER2);
        vm.expectRevert();
        cmtat.crosschainMint(USER3, 10);

        vm.prank(USER2);
        vm.expectRevert();
        cmtat.crosschainBurn(USER1, 10);
    }

    function test_UnpauseRestoresOperations() public {
        vm.startPrank(ADMIN);
        cmtat.pause();
        cmtat.unpause();
        vm.stopPrank();

        vm.prank(USER1);
        assertTrue(cmtat.transfer(USER2, 10));

        vm.prank(USER2);
        cmtat.crosschainMint(USER3, 5);
        assertEq(cmtat.balanceOf(USER3), 5);
    }

    function test_RevertWhen_DeactivateWithoutPause() public {
        vm.prank(ADMIN);
        vm.expectRevert();
        cmtat.deactivateContract();
    }

    function test_DeactivateThenUnpauseRevertsAndReadPathShowsDeactivated() public {
        vm.startPrank(ADMIN);
        cmtat.pause();
        cmtat.deactivateContract();
        vm.expectRevert(CMTAT_PauseModule_ContractIsDeactivated.selector);
        cmtat.unpause();
        vm.stopPrank();

        assertTrue(cmtat.deactivated());
        assertEq(cmtat.detectTransferRestriction(USER1, USER2, 10), 1);
        assertFalse(cmtat.canTransfer(USER1, USER2, 10));
    }

    function _deactivate() internal {
        vm.startPrank(ADMIN);
        cmtat.pause();
        cmtat.deactivateContract();
        vm.stopPrank();
    }

    /// @dev Deactivation is the irreversible kill switch: unlike a pause it also closes mint and
    ///      burn, with a dedicated error rather than the pause one.
    function test_DeactivationBlocksMintAndBurn() public {
        _deactivate();

        vm.prank(USER2);
        vm.expectRevert(EnforcedDeactivation.selector);
        cmtat.mint(USER1, 1);

        vm.prank(USER2);
        vm.expectRevert(EnforcedDeactivation.selector);
        cmtat.burn(USER1, 1, "");
    }

    function test_DeactivationBlocksTransfers() public {
        _deactivate();

        vm.prank(USER1);
        vm.expectRevert();
        cmtat.transfer(USER2, 1);
    }

    /// @dev Enforcement survives the kill switch on purpose: the issuer must still be able to seize
    ///      or burn tokens after the token has been deactivated.
    function test_ForcedTransferStillWorksAfterDeactivation() public {
        _deactivate();

        vm.prank(ADMIN);
        assertTrue(cmtat.forcedTransfer(USER1, USER3, 100));
        assertEq(cmtat.balanceOf(USER3), 100);

        vm.prank(ADMIN);
        assertTrue(cmtat.forcedTransfer(USER1, ZERO_ADDRESS, 50));
        assertEq(cmtat.balanceOf(USER1), 850);
    }

    function test_DeactivateIsRoleGatedAndIdempotent() public {
        vm.prank(ADMIN);
        cmtat.pause();

        vm.prank(USER1);
        vm.expectRevert();
        cmtat.deactivateContract();

        vm.startPrank(ADMIN);
        cmtat.deactivateContract();
        // calling it again on an already deactivated contract is a no-op, not a revert
        cmtat.deactivateContract();
        vm.stopPrank();
        assertTrue(cmtat.deactivated());
    }
}
