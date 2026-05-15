//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import "./HelperContract.sol";

contract PauseModuleTest is HelperContract {
    bytes32 public constant CROSS_CHAIN_ROLE = keccak256("CROSS_CHAIN_ROLE");
    error CMTAT_PauseModule_ContractIsDeactivated();

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
}
