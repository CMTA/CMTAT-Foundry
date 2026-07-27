//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../script/DeployCMTATStandaloneERC7551.s.sol";
import "CMTAT/interfaces/tokenization/draft-IERC7551.sol";
import "CMTAT/interfaces/tokenization/draft-IERC1643CMTAT.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

/// @dev Behaviour of the ERC-7551 variant: the metadata slot and the ERC-7551 flavoured
///      `setTerms(hash, uri)` / `termsHash()` accessors that this variant adds on top of the base.
contract ERC7551ModuleTest is Test {
    CMTATStandaloneERC7551 internal cmtat;

    address internal constant ADMIN = address(1);
    address internal constant USER1 = address(2);

    bytes32 internal constant EXTRA_INFORMATION_ROLE = keccak256("EXTRA_INFORMATION_ROLE");

    function setUp() public {
        DeployCMTATStandaloneERC7551 deployer = new DeployCMTATStandaloneERC7551();
        cmtat = deployer.deploy(
            ADMIN, address(0), "CMTA Token", "CMTAT", 0, "CMTAT_ISIN", "Terms", "https://cmta.ch/terms", "CMTAT_info"
        );
    }

    function test_MetaDataIsEmptyByDefault() public {
        assertEq(cmtat.metaData(), "");
    }

    function test_AdminCanSetMetaDataAndEmitsEvent() public {
        vm.expectEmit(true, true, true, true);
        emit IERC7551Document.MetaData("ipfs://metadata");

        vm.prank(ADMIN);
        cmtat.setMetaData("ipfs://metadata");
        assertEq(cmtat.metaData(), "ipfs://metadata");
    }

    function test_MetaDataCanBeOverwritten() public {
        vm.startPrank(ADMIN);
        cmtat.setMetaData("first");
        cmtat.setMetaData("second");
        vm.stopPrank();
        assertEq(cmtat.metaData(), "second");
    }

    function test_TermsHashReflectsTheDeployedTerms() public {
        // the deploy script sets an empty document hash
        assertEq(cmtat.termsHash(), bytes32(0));
        assertEq(cmtat.terms().doc.uri, "https://cmta.ch/terms");
    }

    function test_AdminCanSetTermsWithHashAndUriAndEmitsEvent() public {
        bytes32 hash_ = keccak256("terms-v2");

        vm.expectEmit(true, true, true, true);
        emit IERC7551Document.Terms(hash_, "https://cmta.ch/terms-v2");

        vm.prank(ADMIN);
        cmtat.setTerms(hash_, "https://cmta.ch/terms-v2");

        assertEq(cmtat.termsHash(), hash_);
        assertEq(cmtat.terms().doc.uri, "https://cmta.ch/terms-v2");
        // the ERC-7551 overload does not carry a document name
        assertEq(cmtat.terms().name, "");
    }

    function test_ExtraInformationRoleCanBeGrantedAndUsed() public {
        vm.prank(ADMIN);
        cmtat.grantRole(EXTRA_INFORMATION_ROLE, USER1);

        vm.startPrank(USER1);
        cmtat.setMetaData("from-role-holder");
        cmtat.setTerms(keccak256("h"), "https://example.com/t");
        vm.stopPrank();

        assertEq(cmtat.metaData(), "from-role-holder");
        assertEq(cmtat.termsHash(), keccak256("h"));
    }

    function test_RevertWhen_NonExtraInformationRoleSetsMetaDataOrTerms() public {
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, USER1, EXTRA_INFORMATION_ROLE
            )
        );
        cmtat.setMetaData("nope");

        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, USER1, EXTRA_INFORMATION_ROLE
            )
        );
        cmtat.setTerms(keccak256("h"), "https://example.com/t");
    }

    function test_BaseSetTermsOverloadStillWorks() public {
        IERC1643CMTAT.DocumentInfo memory newTerms =
            IERC1643CMTAT.DocumentInfo({name: "T2", uri: "https://example.com/t2", documentHash: keccak256("hash")});

        vm.prank(ADMIN);
        cmtat.setTerms(newTerms);

        assertEq(cmtat.terms().name, "T2");
        assertEq(cmtat.termsHash(), keccak256("hash"));
    }
}
