//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../script/DeployCMTATUpgradeableUUPSProxy.s.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";

/// @dev The upgrade path is the main risk of the UUPS variant and was only covered at deployment
///      time: this asserts who may upgrade, that state survives an upgrade, and that the
///      implementation cannot be initialized or re-initialized.
contract UUPSUpgradeTest is Test {
    // ERC-1967 implementation slot: keccak256("eip1967.proxy.implementation") - 1
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    CMTATUpgradeableUUPS internal cmtat;

    address internal constant ADMIN = address(1);
    address internal constant USER1 = address(2);
    address internal constant USER2 = address(3);

    bytes32 internal constant PROXY_UPGRADE_ROLE = keccak256("PROXY_UPGRADE_ROLE");

    function setUp() public {
        DeployCMTATUpgradeableUUPSProxy deployer = new DeployCMTATUpgradeableUUPSProxy();
        cmtat = deployer.deploy(
            ADMIN, address(0), "CMTA Token", "CMTAT", 0, "CMTAT_ISIN", "Terms", "https://cmta.ch/terms", "CMTAT_info"
        );
        vm.prank(ADMIN);
        cmtat.mint(USER1, 1_000);
    }

    function _implementation() internal view returns (address) {
        return address(uint160(uint256(vm.load(address(cmtat), IMPLEMENTATION_SLOT))));
    }

    function test_ProxyPointsAtAnImplementation() public {
        assertTrue(_implementation() != address(0));
        assertTrue(_implementation() != address(cmtat));
    }

    function test_AdminCanUpgradeAndStateIsPreserved() public {
        address newImplementation = address(new CMTATUpgradeableUUPS(address(0)));
        address oldImplementation = _implementation();

        vm.prank(ADMIN);
        cmtat.upgradeToAndCall(newImplementation, "");

        assertEq(_implementation(), newImplementation);
        assertTrue(newImplementation != oldImplementation);

        // storage lives in the proxy, so everything set before the upgrade is still there
        assertEq(cmtat.name(), "CMTA Token");
        assertEq(cmtat.symbol(), "CMTAT");
        assertEq(cmtat.tokenId(), "CMTAT_ISIN");
        assertEq(cmtat.balanceOf(USER1), 1_000);
        assertEq(cmtat.totalSupply(), 1_000);
        assertTrue(cmtat.hasRole(0x00, ADMIN));
    }

    function test_TokenStaysUsableAfterUpgrade() public {
        // deployed before the prank: a `new` inside the call arguments would consume it
        address newImplementation = address(new CMTATUpgradeableUUPS(address(0)));
        vm.prank(ADMIN);
        cmtat.upgradeToAndCall(newImplementation, "");

        vm.prank(USER1);
        cmtat.transfer(USER2, 400);
        assertEq(cmtat.balanceOf(USER2), 400);

        vm.prank(ADMIN);
        cmtat.mint(USER2, 100);
        assertEq(cmtat.balanceOf(USER2), 500);
    }

    function test_ProxyUpgradeRoleHolderCanUpgrade() public {
        vm.prank(ADMIN);
        cmtat.grantRole(PROXY_UPGRADE_ROLE, USER1);

        address newImplementation = address(new CMTATUpgradeableUUPS(address(0)));
        vm.prank(USER1);
        cmtat.upgradeToAndCall(newImplementation, "");

        assertEq(_implementation(), newImplementation);
    }

    function test_RevertWhen_UnauthorizedAccountUpgrades() public {
        address newImplementation = address(new CMTATUpgradeableUUPS(address(0)));
        address before = _implementation();

        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, USER1, PROXY_UPGRADE_ROLE)
        );
        cmtat.upgradeToAndCall(newImplementation, "");

        assertEq(_implementation(), before);
    }

    function test_RevertWhen_RevokedUpgradeRoleTriesToUpgrade() public {
        address newImplementation = address(new CMTATUpgradeableUUPS(address(0)));

        vm.startPrank(ADMIN);
        cmtat.grantRole(PROXY_UPGRADE_ROLE, USER1);
        cmtat.revokeRole(PROXY_UPGRADE_ROLE, USER1);
        vm.stopPrank();

        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, USER1, PROXY_UPGRADE_ROLE)
        );
        cmtat.upgradeToAndCall(newImplementation, "");
    }

    function test_RevertWhen_ProxyIsInitializedTwice() public {
        ICMTATInitializerUUPS initializer = ICMTATInitializerUUPS(address(cmtat));

        vm.expectRevert(Initializable.InvalidInitialization.selector);
        initializer.initialize(
            USER1,
            ICMTATConstructor.ERC20Attributes({name: "X", symbol: "X", decimalsIrrevocable: 0}),
            ICMTATConstructor.ExtraInformationAttributes({
                tokenId: "X",
                terms: IERC1643CMTAT.DocumentInfo({name: "X", uri: "X", documentHash: bytes32(0)}),
                information: "X"
            }),
            ICMTATConstructor.Engine({ruleEngine: IRuleEngine(address(0))})
        );
    }

    function test_RevertWhen_ImplementationIsInitializedDirectly() public {
        // the implementation constructor calls _disableInitializers()
        ICMTATInitializerUUPS implementation = ICMTATInitializerUUPS(_implementation());

        vm.expectRevert(Initializable.InvalidInitialization.selector);
        implementation.initialize(
            USER1,
            ICMTATConstructor.ERC20Attributes({name: "X", symbol: "X", decimalsIrrevocable: 0}),
            ICMTATConstructor.ExtraInformationAttributes({
                tokenId: "X",
                terms: IERC1643CMTAT.DocumentInfo({name: "X", uri: "X", documentHash: bytes32(0)}),
                information: "X"
            }),
            ICMTATConstructor.Engine({ruleEngine: IRuleEngine(address(0))})
        );
    }
}
