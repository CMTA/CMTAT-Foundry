//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../script/DeployCMTATStandaloneAllowlist.s.sol";
import "CMTAT/interfaces/modules/IAllowlistModule.sol";
import "CMTAT/interfaces/tokenization/draft-IERC7943.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

/// @dev Behaviour of the allowlist variant. The deployment tests only cover construction, so the
///      transfer/mint/burn gating implemented by `ValidationModuleAllowlist` is asserted here.
///      Note the allowlist is ENABLED by the initializer and nobody — not even the admin — is
///      allowlisted at deployment, so a fresh token rejects every transfer until addresses are added.
contract AllowlistModuleTest is Test {
    CMTATStandaloneAllowlist internal cmtat;

    address internal constant ADMIN = address(1);
    address internal constant USER1 = address(2);
    address internal constant USER2 = address(3);
    address internal constant USER3 = address(4);

    bytes32 internal constant ALLOWLIST_ROLE = keccak256("ALLOWLIST_ROLE");

    function setUp() public {
        DeployCMTATStandaloneAllowlist deployer = new DeployCMTATStandaloneAllowlist();
        cmtat = deployer.deploy(
            ADMIN, address(0), "CMTA Token", "CMTAT", 0, "CMTAT_ISIN", "Terms", "https://cmta.ch/terms", "CMTAT_info"
        );
        _allowlist(USER1, true);
        vm.prank(ADMIN);
        cmtat.mint(USER1, 1_000);
    }

    function _allowlist(address account, bool status) internal {
        vm.prank(ADMIN);
        cmtat.setAddressAllowlist(account, status);
    }

    function test_AllowlistIsEnabledByDefaultAndNobodyIsListed() public {
        DeployCMTATStandaloneAllowlist deployer = new DeployCMTATStandaloneAllowlist();
        CMTATStandaloneAllowlist fresh = deployer.deploy(
            ADMIN, address(0), "CMTA Token", "CMTAT", 0, "CMTAT_ISIN", "Terms", "https://cmta.ch/terms", "CMTAT_info"
        );

        assertTrue(fresh.isAllowlistEnabled());
        assertFalse(fresh.isAllowlisted(ADMIN));
        assertFalse(fresh.isAllowlisted(USER1));

        // even the admin cannot be minted to before being allowlisted
        vm.prank(ADMIN);
        vm.expectRevert(abi.encodeWithSelector(IERC7943TransactError.ERC7943CannotTransact.selector, ADMIN));
        fresh.mint(ADMIN, 1);
    }

    function test_AllowlistedAddressesCanTransfer() public {
        _allowlist(USER2, true);

        vm.prank(USER1);
        cmtat.transfer(USER2, 100);
        assertEq(cmtat.balanceOf(USER2), 100);
    }

    function test_RevertWhen_ReceiverNotAllowlisted() public {
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IERC7943TransactError.ERC7943CannotTransact.selector, USER2));
        cmtat.transfer(USER2, 100);
    }

    function test_RevertWhen_SenderNotAllowlisted() public {
        _allowlist(USER2, true);
        _allowlist(USER1, false);

        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IERC7943TransactError.ERC7943CannotTransact.selector, USER1));
        cmtat.transfer(USER2, 100);
    }

    function test_RevertWhen_SpenderNotAllowlistedOnTransferFrom() public {
        _allowlist(USER2, true);

        vm.prank(USER1);
        cmtat.approve(USER3, 100);

        vm.prank(USER3);
        vm.expectRevert(abi.encodeWithSelector(IERC7943TransactError.ERC7943CannotTransact.selector, USER3));
        cmtat.transferFrom(USER1, USER2, 100);
    }

    function test_AllowlistedSpenderCanTransferFrom() public {
        _allowlist(USER2, true);
        _allowlist(USER3, true);

        vm.prank(USER1);
        cmtat.approve(USER3, 100);

        vm.prank(USER3);
        cmtat.transferFrom(USER1, USER2, 100);
        assertEq(cmtat.balanceOf(USER2), 100);
        assertEq(cmtat.balanceOf(USER1), 900);
    }

    function test_RevertWhen_MintingToNonAllowlistedAccount() public {
        vm.prank(ADMIN);
        vm.expectRevert(abi.encodeWithSelector(IERC7943TransactError.ERC7943CannotTransact.selector, USER2));
        cmtat.mint(USER2, 10);
    }

    function test_MintAndBurnWorkForAllowlistedAccount() public {
        _allowlist(USER2, true);

        vm.startPrank(ADMIN);
        cmtat.mint(USER2, 10);
        assertEq(cmtat.balanceOf(USER2), 10);
        cmtat.burn(USER2, 4, "");
        vm.stopPrank();
        assertEq(cmtat.balanceOf(USER2), 6);
    }

    function test_RevertWhen_BurningFromDelistedAccount() public {
        _allowlist(USER1, false);

        vm.prank(ADMIN);
        vm.expectRevert(abi.encodeWithSelector(IERC7943TransactError.ERC7943CannotTransact.selector, USER1));
        cmtat.burn(USER1, 10, "");
    }

    function test_DisablingAllowlistRestoresTransfers() public {
        vm.prank(ADMIN);
        cmtat.enableAllowlist(false);
        assertFalse(cmtat.isAllowlistEnabled());

        // USER2 is still not allowlisted, but the list no longer gates anything
        vm.prank(USER1);
        cmtat.transfer(USER2, 100);
        assertEq(cmtat.balanceOf(USER2), 100);

        vm.prank(ADMIN);
        cmtat.mint(USER2, 10);
        assertEq(cmtat.balanceOf(USER2), 110);
    }

    function test_ReEnablingAllowlistGatesTransfersAgain() public {
        vm.startPrank(ADMIN);
        cmtat.enableAllowlist(false);
        cmtat.enableAllowlist(true);
        vm.stopPrank();

        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IERC7943TransactError.ERC7943CannotTransact.selector, USER2));
        cmtat.transfer(USER2, 100);
    }

    function test_BatchSetAddressAllowlist() public {
        address[] memory accounts = new address[](2);
        accounts[0] = USER2;
        accounts[1] = USER3;
        bool[] memory statuses = new bool[](2);
        statuses[0] = true;
        statuses[1] = true;

        vm.prank(ADMIN);
        cmtat.batchSetAddressAllowlist(accounts, statuses);

        assertTrue(cmtat.isAllowlisted(USER2));
        assertTrue(cmtat.isAllowlisted(USER3));

        vm.prank(USER1);
        cmtat.transfer(USER2, 100);
        assertEq(cmtat.balanceOf(USER2), 100);
    }

    function test_SetAddressAllowlistEmitsEventWithData() public {
        vm.expectEmit(true, true, true, true);
        emit IAllowlistModule.AddressAddedToAllowlist(USER2, true, ADMIN, "reason");

        vm.prank(ADMIN);
        cmtat.setAddressAllowlist(USER2, true, "reason");
        assertTrue(cmtat.isAllowlisted(USER2));
    }

    function test_EnableAllowlistEmitsEvent() public {
        vm.expectEmit(true, true, true, true);
        emit IAllowlistModule.AllowlistEnableStatus(ADMIN, false);

        vm.prank(ADMIN);
        cmtat.enableAllowlist(false);
    }

    function test_RemovingAnAddressFromTheAllowlistBlocksItAgain() public {
        _allowlist(USER2, true);
        vm.prank(USER1);
        cmtat.transfer(USER2, 100);

        _allowlist(USER2, false);
        assertFalse(cmtat.isAllowlisted(USER2));

        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IERC7943TransactError.ERC7943CannotTransact.selector, USER2));
        cmtat.transfer(USER2, 100);
    }

    function test_RevertWhen_NonAllowlistRoleManagesAllowlist() public {
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, USER1, ALLOWLIST_ROLE)
        );
        cmtat.setAddressAllowlist(USER2, true);

        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, USER1, ALLOWLIST_ROLE)
        );
        cmtat.enableAllowlist(false);
    }

    function test_ReadPathReflectsTheAllowlist() public {
        assertFalse(cmtat.canTransfer(USER1, USER2, 100));
        assertFalse(cmtat.canTransferFrom(USER3, USER1, USER2, 100));

        _allowlist(USER2, true);
        _allowlist(USER3, true);

        assertTrue(cmtat.canTransfer(USER1, USER2, 100));
        assertTrue(cmtat.canTransferFrom(USER3, USER1, USER2, 100));
    }

    function test_AllowlistRoleCanBeGrantedAndUsed() public {
        vm.prank(ADMIN);
        cmtat.grantRole(ALLOWLIST_ROLE, USER3);

        vm.prank(USER3);
        cmtat.setAddressAllowlist(USER2, true);
        assertTrue(cmtat.isAllowlisted(USER2));
    }
}
