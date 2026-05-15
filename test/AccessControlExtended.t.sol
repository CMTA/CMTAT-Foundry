//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import "./HelperContract.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "CMTAT/interfaces/engine/ISnapshotEngine.sol";
import "CMTAT/interfaces/tokenization/draft-IERC1643.sol";

contract AccessControlExtendedTest is HelperContract {
    bytes32 public constant DOCUMENT_ROLE = keccak256("DOCUMENT_ROLE");
    bytes32 public constant EXTRA_INFORMATION_ROLE = keccak256("EXTRA_INFORMATION_ROLE");
    bytes32 public constant ERC20ENFORCER_ROLE = keccak256("ERC20ENFORCER_ROLE");
    bytes32 public constant SNAPSHOOTER_ROLE = keccak256("SNAPSHOOTER_ROLE");
    bytes32 public constant BURNER_FROM_ROLE = keccak256("BURNER_FROM_ROLE");
    bytes32 public constant BURNER_SELF_ROLE = keccak256("BURNER_SELF_ROLE");
    bytes32 public constant CROSS_CHAIN_ROLE = keccak256("CROSS_CHAIN_ROLE");

    function setUp() public {
        _deployToken();
        vm.startPrank(ADMIN);
        cmtat.mint(USER1, 1_000);
        cmtat.mint(USER2, 200);
        vm.stopPrank();
    }

    function test_RoleGates_SnapshotAndDocumentAndExtraInfo() public {
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, USER1, SNAPSHOOTER_ROLE)
        );
        cmtat.setSnapshotEngine(ISnapshotEngine(address(0x1234)));

        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, USER1, DOCUMENT_ROLE)
        );
        cmtat.setDocumentEngine(IERC1643(address(0x1234)));

        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, USER1, EXTRA_INFORMATION_ROLE)
        );
        cmtat.setInformation("x");
    }

    function test_ERC20EnforcerRoleRequiredForSetFrozenTokens() public {
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, USER1, ERC20ENFORCER_ROLE)
        );
        cmtat.setFrozenTokens(USER2, 10);

        vm.prank(ADMIN);
        cmtat.grantRole(ERC20ENFORCER_ROLE, USER1);
        vm.prank(USER1);
        assertTrue(cmtat.setFrozenTokens(USER2, 10));
        assertEq(cmtat.getFrozenTokens(USER2), 10);
    }

    function test_CrossChainRoleRequiredForCrosschainMintAndBurn() public {
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, USER1, CROSS_CHAIN_ROLE)
        );
        cmtat.crosschainMint(USER3, 1);

        vm.prank(ADMIN);
        cmtat.grantRole(CROSS_CHAIN_ROLE, USER1);

        vm.prank(USER1);
        cmtat.crosschainMint(USER3, 50);
        assertEq(cmtat.balanceOf(USER3), 50);

        vm.prank(USER1);
        cmtat.crosschainBurn(USER3, 20);
        assertEq(cmtat.balanceOf(USER3), 30);
    }

    function test_BurnerFromRoleRequiredForBurnFrom() public {
        vm.prank(USER2);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, USER2, BURNER_FROM_ROLE)
        );
        cmtat.burnFrom(USER1, 1);

        vm.startPrank(ADMIN);
        cmtat.grantRole(BURNER_FROM_ROLE, USER2);
        vm.stopPrank();

        vm.prank(USER1);
        cmtat.approve(USER2, 100);

        vm.prank(USER2);
        cmtat.burnFrom(USER1, 40);
        assertEq(cmtat.balanceOf(USER1), 960);
    }

    function test_BurnerSelfRoleRequiredForSelfBurn() public {
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, USER1, BURNER_SELF_ROLE)
        );
        cmtat.burn(1);

        vm.prank(ADMIN);
        cmtat.grantRole(BURNER_SELF_ROLE, USER1);

        vm.prank(USER1);
        cmtat.burn(60);
        assertEq(cmtat.balanceOf(USER1), 940);
    }

    function test_RevokedRoleCannotUseProtectedFunction() public {
        vm.startPrank(ADMIN);
        cmtat.grantRole(CROSS_CHAIN_ROLE, USER1);
        cmtat.revokeRole(CROSS_CHAIN_ROLE, USER1);
        vm.stopPrank();

        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, USER1, CROSS_CHAIN_ROLE)
        );
        cmtat.crosschainMint(USER2, 1);
    }
}
