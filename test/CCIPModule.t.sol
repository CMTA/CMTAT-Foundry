//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import "./HelperContract.sol";
import "CMTAT/interfaces/technical/IGetCCIPAdmin.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

/// @dev The CCIP admin (Chainlink CCT registration) is part of the base token but was untested.
contract CCIPModuleTest is HelperContract {
    error CMTAT_CCIPModule_SameValue();

    function setUp() public {
        _deployToken();
    }

    function test_CCIPAdminIsUnsetByDefault() public {
        assertEq(cmtat.getCCIPAdmin(), ZERO_ADDRESS);
    }

    function test_AdminCanSetCCIPAdminAndEmitsEvent() public {
        vm.expectEmit(true, true, true, true);
        emit IGetCCIPAdmin.CCIPAdminTransferred(ZERO_ADDRESS, USER1);

        vm.prank(ADMIN);
        cmtat.setCCIPAdmin(USER1);
        assertEq(cmtat.getCCIPAdmin(), USER1);
    }

    function test_CCIPAdminCanBeTransferredAndRevoked() public {
        vm.startPrank(ADMIN);
        cmtat.setCCIPAdmin(USER1);

        vm.expectEmit(true, true, true, true);
        emit IGetCCIPAdmin.CCIPAdminTransferred(USER1, USER2);
        cmtat.setCCIPAdmin(USER2);
        assertEq(cmtat.getCCIPAdmin(), USER2);

        // setting it back to the zero address is the documented way to revoke it
        cmtat.setCCIPAdmin(ZERO_ADDRESS);
        vm.stopPrank();
        assertEq(cmtat.getCCIPAdmin(), ZERO_ADDRESS);
    }

    function test_RevertWhen_SetCCIPAdminSameValue() public {
        vm.startPrank(ADMIN);
        cmtat.setCCIPAdmin(USER1);

        vm.expectRevert(CMTAT_CCIPModule_SameValue.selector);
        cmtat.setCCIPAdmin(USER1);
        vm.stopPrank();
    }

    function test_RevertWhen_SetCCIPAdminToZeroWhileAlreadyUnset() public {
        vm.prank(ADMIN);
        vm.expectRevert(CMTAT_CCIPModule_SameValue.selector);
        cmtat.setCCIPAdmin(ZERO_ADDRESS);
    }

    function test_RevertWhen_NonAdminSetsCCIPAdmin() public {
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, USER1, DEFAULT_ADMIN_ROLE)
        );
        cmtat.setCCIPAdmin(USER2);
    }

    function test_CCIPAdminHasNoTokenPowers() public {
        vm.prank(ADMIN);
        cmtat.setCCIPAdmin(USER1);

        // being the CCIP admin grants no role on the token
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, USER1, MINTER_ROLE)
        );
        cmtat.mint(USER1, 1);
    }
}
