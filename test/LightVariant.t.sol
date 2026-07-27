//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../script/DeployCMTATStandaloneLight.s.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

/// @dev The light variant (`CMTATBaseCore`) was only covered at deployment time. It keeps the core
///      modules — mint, burn, pause, enforcement, version — and drops the rest, which is what
///      makes it worth asserting: the kept behaviour must still hold.
contract LightVariantTest is Test {
    CMTATStandaloneLight internal cmtat;

    address internal constant ADMIN = address(1);
    address internal constant USER1 = address(2);
    address internal constant USER2 = address(3);

    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 internal constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 internal constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 internal constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 internal constant ENFORCER_ROLE = keccak256("ENFORCER_ROLE");

    function setUp() public {
        DeployCMTATStandaloneLight deployer = new DeployCMTATStandaloneLight();
        cmtat = deployer.deploy(ADMIN, "CMTA Token", "CMTAT", 0);
        vm.prank(ADMIN);
        cmtat.mint(USER1, 1_000);
    }

    function test_VersionIsExposed() public {
        assertEq(cmtat.version(), "3.2.0");
    }

    function test_CoreERC20FlowsWork() public {
        vm.prank(USER1);
        cmtat.transfer(USER2, 300);
        assertEq(cmtat.balanceOf(USER2), 300);
        assertEq(cmtat.balanceOf(USER1), 700);

        vm.prank(USER1);
        cmtat.approve(USER2, 200);
        vm.prank(USER2);
        cmtat.transferFrom(USER1, USER2, 200);
        assertEq(cmtat.balanceOf(USER2), 500);
        assertEq(cmtat.allowance(USER1, USER2), 0);
    }

    function test_MintAndBurnAreRoleGated() public {
        vm.prank(ADMIN);
        cmtat.grantRole(MINTER_ROLE, USER1);
        vm.prank(USER1);
        cmtat.mint(USER2, 50);
        assertEq(cmtat.balanceOf(USER2), 50);

        vm.prank(USER2);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, USER2, MINTER_ROLE)
        );
        cmtat.mint(USER2, 50);

        vm.prank(USER2);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, USER2, BURNER_ROLE)
        );
        cmtat.burn(USER1, 10, "");
    }

    function test_PauseBlocksTransfersAndUnpauseRestoresThem() public {
        vm.prank(ADMIN);
        cmtat.pause();
        assertTrue(cmtat.paused());

        vm.prank(USER1);
        vm.expectRevert();
        cmtat.transfer(USER2, 10);

        vm.prank(ADMIN);
        cmtat.unpause();
        vm.prank(USER1);
        cmtat.transfer(USER2, 10);
        assertEq(cmtat.balanceOf(USER2), 10);
    }

    function test_PauseIsRoleGated() public {
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, USER1, PAUSER_ROLE)
        );
        cmtat.pause();
    }

    function test_FrozenAddressCannotTransfer() public {
        vm.prank(ADMIN);
        cmtat.setAddressFrozen(USER1, true);
        assertTrue(cmtat.isFrozen(USER1));

        vm.prank(USER1);
        vm.expectRevert();
        cmtat.transfer(USER2, 10);

        vm.prank(ADMIN);
        cmtat.setAddressFrozen(USER1, false);
        vm.prank(USER1);
        cmtat.transfer(USER2, 10);
        assertEq(cmtat.balanceOf(USER2), 10);
    }

    function test_FreezeIsRoleGated() public {
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, USER1, ENFORCER_ROLE)
        );
        cmtat.setAddressFrozen(USER2, true);
    }

    function test_AdminHoldsEveryRole() public {
        assertTrue(cmtat.hasRole(DEFAULT_ADMIN_ROLE, ADMIN));
        assertTrue(cmtat.hasRole(MINTER_ROLE, ADMIN));
        assertTrue(cmtat.hasRole(BURNER_ROLE, ADMIN));
        assertTrue(cmtat.hasRole(PAUSER_ROLE, ADMIN));
        assertTrue(cmtat.hasRole(ENFORCER_ROLE, ADMIN));
    }
}
