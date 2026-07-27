//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../script/DeployCMTATStandaloneERC1363.s.sol";
import "./MockERC1363.sol";
import "@openzeppelin/contracts/interfaces/IERC1363.sol";
import "@openzeppelin/contracts/token/ERC20/utils/ERC1363Utils.sol";

/// @dev Behaviour of the ERC-1363 variant. The deployment test only covers the `transferAndCall`
///      happy path, so the callback payload, the spender path and the rejection paths are asserted here.
contract ERC1363ModuleTest is Test {
    CMTATStandaloneERC1363 internal cmtat;
    MockERC1363Receiver internal receiver;
    MockERC1363Spender internal spender;

    address internal constant ADMIN = address(1);
    address internal constant USER1 = address(2);
    address internal constant USER2 = address(3);

    function setUp() public {
        DeployCMTATStandaloneERC1363 deployer = new DeployCMTATStandaloneERC1363();
        cmtat = deployer.deploy(
            ADMIN, address(0), "CMTA Token", "CMTAT", 0, "CMTAT_ISIN", "Terms", "https://cmta.ch/terms", "CMTAT_info"
        );
        receiver = new MockERC1363Receiver();
        spender = new MockERC1363Spender();

        vm.prank(ADMIN);
        cmtat.mint(USER1, 1_000);
    }

    function test_TransferAndCallForwardsOperatorFromAndData() public {
        vm.prank(USER1);
        assertTrue(cmtat.transferAndCall(address(receiver), 100, "payload"));

        assertEq(cmtat.balanceOf(address(receiver)), 100);
        assertEq(cmtat.balanceOf(USER1), 900);
        assertEq(receiver.lastOperator(), USER1);
        assertEq(receiver.lastFrom(), USER1);
        assertEq(receiver.lastValue(), 100);
        assertEq(receiver.lastData(), "payload");
    }

    function test_TransferFromAndCallConsumesAllowance() public {
        vm.prank(USER1);
        cmtat.approve(USER2, 300);

        vm.prank(USER2);
        assertTrue(cmtat.transferFromAndCall(USER1, address(receiver), 300, "from-call"));

        assertEq(cmtat.balanceOf(address(receiver)), 300);
        assertEq(cmtat.allowance(USER1, USER2), 0);
        assertEq(receiver.lastOperator(), USER2);
        assertEq(receiver.lastFrom(), USER1);
        assertEq(receiver.lastData(), "from-call");
    }

    function test_ApproveAndCallSetsAllowanceAndNotifiesSpender() public {
        vm.prank(USER1);
        assertTrue(cmtat.approveAndCall(address(spender), 250, "approve-payload"));

        assertEq(cmtat.allowance(USER1, address(spender)), 250);
        assertEq(spender.lastOwner(), USER1);
        assertEq(spender.lastValue(), 250);
        assertEq(spender.lastData(), "approve-payload");
    }

    function test_RevertWhen_TransferAndCallToEOA() public {
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ERC1363Utils.ERC1363InvalidReceiver.selector, USER2));
        cmtat.transferAndCall(USER2, 100);
    }

    function test_RevertWhen_ReceiverReturnsWrongSelector() public {
        MockERC1363RejectingReceiver rejecting = new MockERC1363RejectingReceiver();

        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ERC1363Utils.ERC1363InvalidReceiver.selector, address(rejecting)));
        cmtat.transferAndCall(address(rejecting), 100);

        assertEq(cmtat.balanceOf(address(rejecting)), 0);
        assertEq(cmtat.balanceOf(USER1), 1_000);
    }

    function test_RevertWhen_ApproveAndCallOnNonSpenderContract() public {
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ERC1363Utils.ERC1363InvalidSpender.selector, address(receiver)));
        cmtat.approveAndCall(address(receiver), 100);
    }

    function test_RevertWhen_TransferAndCallWhilePaused() public {
        vm.prank(ADMIN);
        cmtat.pause();

        vm.prank(USER1);
        vm.expectRevert();
        cmtat.transferAndCall(address(receiver), 100);

        assertEq(cmtat.balanceOf(address(receiver)), 0);
    }

    function test_TransferAndCallFromFrozenAddressIsBlocked() public {
        vm.prank(ADMIN);
        cmtat.setAddressFrozen(USER1, true);

        vm.prank(USER1);
        vm.expectRevert();
        cmtat.transferAndCall(address(receiver), 100);

        assertEq(cmtat.balanceOf(address(receiver)), 0);
    }

    function test_SupportsERC1363Interface() public {
        assertTrue(cmtat.supportsInterface(type(IERC1363).interfaceId));
    }
}
