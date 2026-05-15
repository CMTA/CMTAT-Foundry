//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import "./HelperContract.sol";
import "./MockDocumentEngine.sol";
import "./MockSnapshotEngine.sol";
import "CMTAT/interfaces/tokenization/ICMTAT.sol";
import "CMTAT/interfaces/tokenization/draft-IERC1643CMTAT.sol";
import "CMTAT/interfaces/modules/IDocumentEngineModule.sol";
import "CMTAT/interfaces/modules/ISnapshotEngineModule.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

contract ExtraInformationAndDocumentTest is HelperContract {
    bytes32 public constant EXTRA_INFORMATION_ROLE = keccak256("EXTRA_INFORMATION_ROLE");
    bytes32 public constant DOCUMENT_ROLE = keccak256("DOCUMENT_ROLE");
    bytes32 public constant SNAPSHOOTER_ROLE = keccak256("SNAPSHOOTER_ROLE");

    error CMTAT_DocumentEngineModule_SameValue();
    error CMTAT_SnapshotModule_SameValue();

    MockDocumentEngine internal documentEngine;
    MockSnapshotEngine internal snapshotEngine;

    function setUp() public {
        _deployToken();
        documentEngine = new MockDocumentEngine();
        snapshotEngine = new MockSnapshotEngine();
    }

    function test_ExtraInformationRoleCanSetTokenIdAndInformation() public {
        vm.startPrank(ADMIN);
        cmtat.grantRole(EXTRA_INFORMATION_ROLE, USER1);
        vm.stopPrank();

        vm.prank(USER1);
        cmtat.setTokenId("NEW_ID");
        assertEq(cmtat.tokenId(), "NEW_ID");

        vm.prank(USER1);
        cmtat.setInformation("new-info");
        assertEq(cmtat.information(), "new-info");
    }

    function test_RevertWhen_NonExtraInformationRoleTriesToSetData() public {
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, USER1, EXTRA_INFORMATION_ROLE)
        );
        cmtat.setTokenId("X");
    }

    function test_SetTermsUpdatesStoredTerms() public {
        vm.startPrank(ADMIN);
        cmtat.grantRole(EXTRA_INFORMATION_ROLE, USER1);
        vm.stopPrank();

        IERC1643CMTAT.DocumentInfo memory newTerms =
            IERC1643CMTAT.DocumentInfo({name: "T2", uri: "https://example.com/t2", documentHash: keccak256("hash")});

        vm.prank(USER1);
        cmtat.setTerms(newTerms);

        ICMTATBase.CMTATTerms memory currentTerms = cmtat.terms();
        assertEq(currentTerms.name, "T2");
        assertEq(currentTerms.doc.uri, "https://example.com/t2");
        assertEq(currentTerms.doc.documentHash, keccak256("hash"));
        assertGt(currentTerms.doc.lastModified, 0);
    }

    function test_DocumentRoleCanSetDocumentEngineAndReadThrough() public {
        vm.startPrank(ADMIN);
        cmtat.grantRole(DOCUMENT_ROLE, USER1);
        vm.stopPrank();

        documentEngine.setDocument("KYC", "ipfs://kyc", keccak256("kyc"), 123);

        vm.prank(USER1);
        cmtat.setDocumentEngine(IERC1643(address(documentEngine)));
        assertEq(address(cmtat.documentEngine()), address(documentEngine));

        IERC1643.Document memory doc = cmtat.getDocument("KYC");
        assertEq(doc.uri, "ipfs://kyc");
        assertEq(doc.documentHash, keccak256("kyc"));
        assertEq(doc.lastModified, 123);
    }

    function test_RevertWhen_SetDocumentEngineSameValue() public {
        vm.startPrank(ADMIN);
        cmtat.grantRole(DOCUMENT_ROLE, USER1);
        vm.stopPrank();

        vm.prank(USER1);
        cmtat.setDocumentEngine(IERC1643(address(documentEngine)));

        vm.prank(USER1);
        vm.expectRevert(CMTAT_DocumentEngineModule_SameValue.selector);
        cmtat.setDocumentEngine(IERC1643(address(documentEngine)));
    }

    function test_SnapshooterRoleCanSetSnapshotEngineAndTransferTriggersIt() public {
        vm.startPrank(ADMIN);
        cmtat.grantRole(SNAPSHOOTER_ROLE, USER1);
        cmtat.mint(USER2, 100);
        vm.stopPrank();

        vm.prank(USER1);
        cmtat.setSnapshotEngine(snapshotEngine);
        assertEq(address(cmtat.snapshotEngine()), address(snapshotEngine));

        vm.prank(USER2);
        cmtat.transfer(USER3, 40);

        assertEq(snapshotEngine.calls(), 1);
        assertEq(snapshotEngine.lastFrom(), USER2);
        assertEq(snapshotEngine.lastTo(), USER3);
        assertEq(snapshotEngine.lastBalanceFrom(), 100);
        assertEq(snapshotEngine.lastBalanceTo(), 0);
        assertEq(snapshotEngine.lastTotalSupply(), 100);
    }

    function test_RevertWhen_SetSnapshotEngineSameValue() public {
        vm.startPrank(ADMIN);
        cmtat.grantRole(SNAPSHOOTER_ROLE, USER1);
        vm.stopPrank();

        vm.prank(USER1);
        cmtat.setSnapshotEngine(snapshotEngine);

        vm.prank(USER1);
        vm.expectRevert(CMTAT_SnapshotModule_SameValue.selector);
        cmtat.setSnapshotEngine(snapshotEngine);
    }
}
