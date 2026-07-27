//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import "./HelperContract.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

contract ERC20BaseAdminTest is HelperContract {
    event Name(string indexed newNameIndexed, string newName);
    event Symbol(string indexed newSymbolIndexed, string newSymbol);

    function setUp() public {
        _deployToken();
        vm.startPrank(ADMIN);
        cmtat.mint(USER1, 31);
        cmtat.mint(USER2, 32);
        cmtat.mint(USER3, 33);
        vm.stopPrank();
    }

    /// @dev Pins the CMTAT release this repository is built against; bump it with the submodule.
    function test_VersionMatchesTheExpectedCMTATRelease() public {
        assertEq(cmtat.version(), "3.2.0");
    }

    function test_AdminCanSetNameAndEmitsEvent() public {
        vm.prank(ADMIN);
        vm.expectEmit(true, false, false, true);
        emit Name("New Name", "New Name");
        cmtat.setName("New Name");
        assertEq(cmtat.name(), "New Name");
    }

    function test_RevertWhen_NonAdminSetsName() public {
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, USER1, DEFAULT_ADMIN_ROLE)
        );
        cmtat.setName("bad");
    }

    function test_AdminCanSetSymbolAndEmitsEvent() public {
        vm.prank(ADMIN);
        vm.expectEmit(true, false, false, true);
        emit Symbol("N", "N");
        cmtat.setSymbol("N");
        assertEq(cmtat.symbol(), "N");
    }

    function test_RevertWhen_NonAdminSetsSymbol() public {
        vm.prank(USER2);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, USER2, DEFAULT_ADMIN_ROLE)
        );
        cmtat.setSymbol("bad");
    }

    function test_BatchBalanceOfWithValuesAndEmptyInput() public {
        address[] memory addrs = new address[](3);
        addrs[0] = USER1;
        addrs[1] = USER2;
        addrs[2] = USER3;
        (uint256[] memory balances, uint256 total) = cmtat.batchBalanceOf(addrs);
        assertEq(balances[0], 31);
        assertEq(balances[1], 32);
        assertEq(balances[2], 33);
        assertEq(total, 96);

        address[] memory empty = new address[](0);
        (uint256[] memory emptyBalances, uint256 total2) = cmtat.batchBalanceOf(empty);
        assertEq(emptyBalances.length, 0);
        assertEq(total2, 96);
    }
}
