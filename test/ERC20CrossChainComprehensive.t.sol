//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import "./HelperContract.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "CMTAT/interfaces/technical/IERC7802.sol";

contract ERC20CrossChainComprehensiveTest is HelperContract {
    bytes32 public constant CROSS_CHAIN_ROLE = keccak256("CROSS_CHAIN_ROLE");
    bytes32 public constant BURNER_FROM_ROLE = keccak256("BURNER_FROM_ROLE");
    bytes32 public constant BURNER_SELF_ROLE = keccak256("BURNER_SELF_ROLE");

    event CrosschainMint(address indexed to, uint256 amount, address indexed sender);
    event CrosschainBurn(address indexed from, uint256 amount, address indexed sender);
    event BurnFrom(address indexed sender, address indexed account, address indexed operator, uint256 amount);
    event Spend(address indexed owner, address indexed spender, uint256 amount);

    function setUp() public {
        _deployToken();
        vm.startPrank(ADMIN);
        cmtat.mint(USER1, 1_000);
        cmtat.grantRole(CROSS_CHAIN_ROLE, USER2);
        cmtat.grantRole(BURNER_FROM_ROLE, USER2);
        cmtat.grantRole(BURNER_SELF_ROLE, USER1);
        vm.stopPrank();
    }

    function test_SupportsExpectedInterfaces() public {
        assertTrue(cmtat.supportsInterface(type(IERC7802).interfaceId));
        assertTrue(cmtat.supportsInterface(0x01ffc9a7));
        assertFalse(cmtat.supportsInterface(0x80ac58cd));
        // the full token advertises ERC-5679 and ERC-7943; the light/core variant only ERC-5679
        assertTrue(cmtat.supportsInterface(0xd0017968));
        assertTrue(cmtat.supportsInterface(0x29388973));
    }

    function test_CrosschainMintAndBurnEmitExpectedEvents() public {
        vm.prank(USER2);
        vm.expectEmit(true, false, true, true);
        emit CrosschainMint(USER3, 120, USER2);
        cmtat.crosschainMint(USER3, 120);
        assertEq(cmtat.balanceOf(USER3), 120);

        vm.prank(USER2);
        vm.expectEmit(true, false, true, true);
        emit CrosschainBurn(USER3, 20, USER2);
        cmtat.crosschainBurn(USER3, 20);
        assertEq(cmtat.balanceOf(USER3), 100);
    }

    function test_BurnFromConsumesAllowanceAndEmitsSpendAndBurnFrom() public {
        vm.prank(USER1);
        cmtat.approve(USER2, 100);

        vm.prank(USER2);
        vm.expectEmit(true, true, false, true);
        emit Spend(USER1, USER2, 40);
        vm.expectEmit(true, true, true, true);
        emit BurnFrom(USER2, USER1, USER2, 40);
        cmtat.burnFrom(USER1, 40);

        assertEq(cmtat.allowance(USER1, USER2), 60);
        assertEq(cmtat.balanceOf(USER1), 960);
    }

    function test_RevertWhen_BurnFromExceedsAllowance() public {
        vm.prank(USER1);
        cmtat.approve(USER2, 10);

        vm.prank(USER2);
        vm.expectRevert();
        cmtat.burnFrom(USER1, 11);
    }

    function test_RevertWhen_CrosschainBurnFromFrozenAddress() public {
        vm.prank(ADMIN);
        cmtat.setAddressFrozen(USER1, true);

        vm.prank(USER2);
        vm.expectRevert();
        cmtat.crosschainBurn(USER1, 1);
    }

    function test_RevertWhen_CrosschainMintToFrozenAddress() public {
        vm.prank(ADMIN);
        cmtat.setAddressFrozen(USER3, true);

        vm.prank(USER2);
        vm.expectRevert();
        cmtat.crosschainMint(USER3, 1);

        assertEq(cmtat.balanceOf(USER3), 0);
    }

    /// @dev A bridge holding `CROSS_CHAIN_ROLE` burns without an ERC-20 allowance — that is the
    ///      point of the role, and why it must be granted only to trusted bridges.
    function test_CrosschainBurnNeedsNoAllowance() public {
        uint256 balanceBefore = cmtat.balanceOf(USER1);
        assertEq(cmtat.allowance(USER1, USER2), 0);

        vm.prank(USER2);
        cmtat.crosschainBurn(USER1, 10);

        assertEq(cmtat.balanceOf(USER1), balanceBefore - 10);
    }

    function test_RevertWhen_CrosschainBurnWhilePaused() public {
        vm.prank(ADMIN);
        cmtat.pause();

        vm.prank(USER2);
        vm.expectRevert();
        cmtat.crosschainBurn(USER1, 1);
    }

    function test_RevertWhen_BurnSelfWhilePaused() public {
        vm.prank(ADMIN);
        cmtat.pause();

        vm.prank(USER1);
        vm.expectRevert();
        cmtat.burn(1);
    }

    function test_RevertWhen_NoCrossChainRole() public {
        vm.prank(USER3);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, USER3, CROSS_CHAIN_ROLE)
        );
        cmtat.crosschainMint(USER1, 1);
    }
}
