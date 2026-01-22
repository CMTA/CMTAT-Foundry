//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import "./HelperContract.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ERC20ModuleTest is HelperContract {
    uint256 constant INITIAL_SUPPLY = 1000;

    function setUp() public {
        _deployToken();
        // Mint initial tokens to USER1
        vm.prank(ADMIN);
        cmtat.mint(USER1, INITIAL_SUPPLY);
    }

    // ============ Token Metadata Tests ============

    function test_Name() public {
        assertEq(cmtat.name(), TOKEN_NAME);
    }

    function test_Symbol() public {
        assertEq(cmtat.symbol(), TOKEN_SYMBOL);
    }

    function test_Decimals() public {
        assertEq(cmtat.decimals(), TOKEN_DECIMALS);
    }

    // ============ Balance and Supply Tests ============

    function test_TotalSupply() public {
        assertEq(cmtat.totalSupply(), INITIAL_SUPPLY);
    }

    function test_BalanceOf() public {
        assertEq(cmtat.balanceOf(USER1), INITIAL_SUPPLY);
        assertEq(cmtat.balanceOf(USER2), 0);
    }

    // ============ Transfer Tests ============

    function test_Transfer() public {
        uint256 transferAmount = 100;

        vm.prank(USER1);
        vm.expectEmit(true, true, false, true);
        emit IERC20.Transfer(USER1, USER2, transferAmount);
        bool success = cmtat.transfer(USER2, transferAmount);

        assertTrue(success);
        assertEq(cmtat.balanceOf(USER1), INITIAL_SUPPLY - transferAmount);
        assertEq(cmtat.balanceOf(USER2), transferAmount);
    }

    function test_TransferEntireBalance() public {
        vm.prank(USER1);
        bool success = cmtat.transfer(USER2, INITIAL_SUPPLY);

        assertTrue(success);
        assertEq(cmtat.balanceOf(USER1), 0);
        assertEq(cmtat.balanceOf(USER2), INITIAL_SUPPLY);
    }

    function test_TransferToSelf() public {
        uint256 balanceBefore = cmtat.balanceOf(USER1);

        vm.prank(USER1);
        bool success = cmtat.transfer(USER1, 100);

        assertTrue(success);
        assertEq(cmtat.balanceOf(USER1), balanceBefore);
    }

    function test_RevertWhen_TransferExceedsBalance() public {
        vm.prank(USER1);
        vm.expectRevert();
        cmtat.transfer(USER2, INITIAL_SUPPLY + 1);
    }

    function test_RevertWhen_TransferToZeroAddress() public {
        vm.prank(USER1);
        vm.expectRevert();
        cmtat.transfer(ZERO_ADDRESS, 100);
    }

    // ============ Approve and Allowance Tests ============

    function test_Approve() public {
        uint256 approveAmount = 500;

        vm.prank(USER1);
        vm.expectEmit(true, true, false, true);
        emit IERC20.Approval(USER1, USER2, approveAmount);
        bool success = cmtat.approve(USER2, approveAmount);

        assertTrue(success);
        assertEq(cmtat.allowance(USER1, USER2), approveAmount);
    }

    function test_ApproveOverwrite() public {
        // First approval
        vm.prank(USER1);
        cmtat.approve(USER2, 500);
        assertEq(cmtat.allowance(USER1, USER2), 500);

        // Overwrite with new amount
        vm.prank(USER1);
        cmtat.approve(USER2, 200);
        assertEq(cmtat.allowance(USER1, USER2), 200);
    }

    function test_ApproveToZero() public {
        vm.prank(USER1);
        cmtat.approve(USER2, 500);

        vm.prank(USER1);
        cmtat.approve(USER2, 0);

        assertEq(cmtat.allowance(USER1, USER2), 0);
    }

    // ============ TransferFrom Tests ============

    function test_TransferFrom() public {
        uint256 approveAmount = 500;
        uint256 transferAmount = 200;

        // USER1 approves USER2
        vm.prank(USER1);
        cmtat.approve(USER2, approveAmount);

        // USER2 transfers from USER1 to USER3
        vm.prank(USER2);
        vm.expectEmit(true, true, false, true);
        emit IERC20.Transfer(USER1, USER3, transferAmount);
        bool success = cmtat.transferFrom(USER1, USER3, transferAmount);

        assertTrue(success);
        assertEq(cmtat.balanceOf(USER1), INITIAL_SUPPLY - transferAmount);
        assertEq(cmtat.balanceOf(USER3), transferAmount);
        assertEq(cmtat.allowance(USER1, USER2), approveAmount - transferAmount);
    }

    function test_TransferFromWithExactAllowance() public {
        uint256 amount = 300;

        vm.prank(USER1);
        cmtat.approve(USER2, amount);

        vm.prank(USER2);
        bool success = cmtat.transferFrom(USER1, USER3, amount);

        assertTrue(success);
        assertEq(cmtat.allowance(USER1, USER2), 0);
    }

    function test_RevertWhen_TransferFromExceedsAllowance() public {
        vm.prank(USER1);
        cmtat.approve(USER2, 100);

        vm.prank(USER2);
        vm.expectRevert();
        cmtat.transferFrom(USER1, USER3, 200);
    }

    function test_RevertWhen_TransferFromExceedsBalance() public {
        // Approve more than balance
        vm.prank(USER1);
        cmtat.approve(USER2, INITIAL_SUPPLY + 100);

        vm.prank(USER2);
        vm.expectRevert();
        cmtat.transferFrom(USER1, USER3, INITIAL_SUPPLY + 1);
    }

    function test_RevertWhen_TransferFromWithoutApproval() public {
        vm.prank(USER2);
        vm.expectRevert();
        cmtat.transferFrom(USER1, USER3, 100);
    }
}
