//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "CMTAT/deployment/CMTATStandalone.sol";
import "CMTAT/interfaces/technical/ICMTATConstructor.sol";
import "CMTAT/interfaces/tokenization/draft-IERC1643CMTAT.sol";
import "./MockTrustedForwarder.sol";

contract ERC2771ModuleTest is Test {
    CMTATStandalone internal cmtat;
    MockTrustedForwarder internal trustedForwarder;
    MockTrustedForwarder internal untrustedForwarder;

    address internal constant ADMIN = address(1);
    address internal constant USER1 = address(2);
    address internal constant USER2 = address(3);

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    function setUp() public {
        trustedForwarder = new MockTrustedForwarder();
        untrustedForwarder = new MockTrustedForwarder();

        ICMTATConstructor.ERC20Attributes memory erc20Attributes =
            ICMTATConstructor.ERC20Attributes({name: "CMTA Token", symbol: "CMTAT", decimalsIrrevocable: 0});
        IERC1643CMTAT.DocumentInfo memory termsDoc =
            IERC1643CMTAT.DocumentInfo({name: "Terms", uri: "https://cmta.ch/terms", documentHash: bytes32(0)});
        ICMTATConstructor.ExtraInformationAttributes memory extraInfoAttributes =
            ICMTATConstructor.ExtraInformationAttributes({tokenId: "CMTAT_ISIN", terms: termsDoc, information: "info"});
        ICMTATConstructor.Engine memory engines = ICMTATConstructor.Engine({ruleEngine: IRuleEngine(address(0))});

        vm.prank(ADMIN);
        cmtat = new CMTATStandalone(address(trustedForwarder), ADMIN, erc20Attributes, extraInfoAttributes, engines);

        vm.prank(ADMIN);
        cmtat.mint(USER1, 1_000);
    }

    function test_IsTrustedForwarderFlags() public {
        assertTrue(cmtat.isTrustedForwarder(address(trustedForwarder)));
        assertFalse(cmtat.isTrustedForwarder(address(untrustedForwarder)));
    }

    function test_TrustedForwarderTransferUsesAppendedSigner() public {
        bytes memory callData = abi.encodeCall(cmtat.transfer, (USER2, 100));
        trustedForwarder.forward(address(cmtat), callData, USER1);

        assertEq(cmtat.balanceOf(USER1), 900);
        assertEq(cmtat.balanceOf(USER2), 100);
    }

    function test_UntrustedForwarderCannotImpersonateSigner() public {
        bytes memory callData = abi.encodeCall(cmtat.transfer, (USER2, 100));
        vm.expectRevert();
        untrustedForwarder.forward(address(cmtat), callData, USER1);
    }

    function test_TrustedForwarderRespectsRoleChecksViaSigner() public {
        vm.prank(ADMIN);
        cmtat.grantRole(MINTER_ROLE, USER1);

        bytes memory callData = abi.encodeWithSignature("mint(address,uint256)", USER2, 50);
        trustedForwarder.forward(address(cmtat), callData, USER1);
        assertEq(cmtat.balanceOf(USER2), 50);
    }
}
