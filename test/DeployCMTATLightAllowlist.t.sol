//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../script/DeployCMTATStandaloneLight.s.sol";
import "../script/DeployCMTATUpgradeableLightProxy.s.sol";
import "../script/DeployCMTATStandaloneAllowlist.s.sol";
import "../script/DeployCMTATUpgradeableAllowlistProxy.s.sol";

abstract contract DeploymentTestBase is Test {
    address internal constant ADMIN = address(1);
    address internal constant FORWARDER = address(2);
    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;

    function _assertCoreMetadata(address token, string memory name_, string memory symbol_, uint8 decimals_) internal {
        assertEq(CMTATStandaloneLight(token).name(), name_);
        assertEq(CMTATStandaloneLight(token).symbol(), symbol_);
        assertEq(CMTATStandaloneLight(token).decimals(), decimals_);
    }

    function _assertAdminRole(address token) internal {
        assertTrue(CMTATStandaloneLight(token).hasRole(DEFAULT_ADMIN_ROLE, ADMIN));
    }
}

contract DeployCMTATLightVersionsTest is DeploymentTestBase {
    DeployCMTATStandaloneLight internal standaloneDeployer;
    DeployCMTATUpgradeableLightProxy internal proxyDeployer;

    function setUp() public {
        standaloneDeployer = new DeployCMTATStandaloneLight();
        proxyDeployer = new DeployCMTATUpgradeableLightProxy();
    }

    function test_DeployStandaloneLight_Defaults() public {
        CMTATStandaloneLight cmtat = standaloneDeployer.deploy(
            ADMIN,
            standaloneDeployer.DEFAULT_NAME(),
            standaloneDeployer.DEFAULT_SYMBOL(),
            standaloneDeployer.DEFAULT_DECIMALS()
        );
        _assertCoreMetadata(address(cmtat), "CMTA Token", "CMTAT", 0);
        _assertAdminRole(address(cmtat));
    }

    function test_DeployUpgradeableLightProxy_Defaults() public {
        CMTATUpgradeableLight cmtat = proxyDeployer.deploy(
            ADMIN, proxyDeployer.DEFAULT_NAME(), proxyDeployer.DEFAULT_SYMBOL(), proxyDeployer.DEFAULT_DECIMALS()
        );
        _assertCoreMetadata(address(cmtat), "CMTA Token", "CMTAT", 0);
        _assertAdminRole(address(cmtat));
    }

    function test_RevertWhen_DeployLightWithZeroAdmin() public {
        vm.expectRevert();
        standaloneDeployer.deploy(address(0), "N", "S", 0);

        vm.expectRevert();
        proxyDeployer.deploy(address(0), "N", "S", 0);
    }
}

contract DeployCMTATAllowlistVersionsTest is DeploymentTestBase {
    DeployCMTATStandaloneAllowlist internal standaloneDeployer;
    DeployCMTATUpgradeableAllowlistProxy internal proxyDeployer;

    function setUp() public {
        standaloneDeployer = new DeployCMTATStandaloneAllowlist();
        proxyDeployer = new DeployCMTATUpgradeableAllowlistProxy();
    }

    function _assertAllowlistMetadata(address token) internal {
        _assertCoreMetadata(token, "CMTA Token", "CMTAT", 0);
        assertEq(CMTATStandaloneAllowlist(token).tokenId(), "CMTAT_ISIN");
        assertEq(CMTATStandaloneAllowlist(token).information(), "CMTAT_info");
        _assertAdminRole(token);
    }

    function test_DeployStandaloneAllowlist_DefaultsAndForwarder() public {
        CMTATStandaloneAllowlist cmtat = standaloneDeployer.deploy(
            ADMIN,
            FORWARDER,
            standaloneDeployer.DEFAULT_NAME(),
            standaloneDeployer.DEFAULT_SYMBOL(),
            standaloneDeployer.DEFAULT_DECIMALS(),
            standaloneDeployer.DEFAULT_TOKEN_ID(),
            standaloneDeployer.DEFAULT_TERMS_NAME(),
            standaloneDeployer.DEFAULT_TERMS_URI(),
            standaloneDeployer.DEFAULT_INFO()
        );
        _assertAllowlistMetadata(address(cmtat));
        assertTrue(cmtat.isTrustedForwarder(FORWARDER));
    }

    function test_DeployUpgradeableAllowlistProxy_DefaultsAndForwarder() public {
        CMTATUpgradeableAllowlist cmtat = proxyDeployer.deploy(
            ADMIN,
            FORWARDER,
            proxyDeployer.DEFAULT_NAME(),
            proxyDeployer.DEFAULT_SYMBOL(),
            proxyDeployer.DEFAULT_DECIMALS(),
            proxyDeployer.DEFAULT_TOKEN_ID(),
            proxyDeployer.DEFAULT_TERMS_NAME(),
            proxyDeployer.DEFAULT_TERMS_URI(),
            proxyDeployer.DEFAULT_INFO()
        );
        _assertAllowlistMetadata(address(cmtat));
        assertTrue(cmtat.isTrustedForwarder(FORWARDER));
    }

    function test_RevertWhen_DeployAllowlistWithZeroAdmin() public {
        vm.expectRevert();
        standaloneDeployer.deploy(address(0), FORWARDER, "N", "S", 0, "ID", "T", "U", "I");

        vm.expectRevert();
        proxyDeployer.deploy(address(0), FORWARDER, "N", "S", 0, "ID", "T", "U", "I");
    }
}
