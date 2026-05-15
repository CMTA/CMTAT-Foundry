//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../script/DeployCMTATStandaloneERC7551.s.sol";
import "../script/DeployCMTATUpgradeableERC7551Proxy.s.sol";

contract DeployCMTATERC7551VersionsTest is Test {
    DeployCMTATStandaloneERC7551 internal standaloneDeployer;
    DeployCMTATUpgradeableERC7551Proxy internal proxyDeployer;

    address internal constant ADMIN = address(1);
    address internal constant FORWARDER = address(2);
    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;

    function setUp() public {
        standaloneDeployer = new DeployCMTATStandaloneERC7551();
        proxyDeployer = new DeployCMTATUpgradeableERC7551Proxy();
    }

    function _assertCommon(address token) internal {
        assertEq(CMTATStandaloneERC7551(token).name(), "CMTA Token");
        assertEq(CMTATStandaloneERC7551(token).symbol(), "CMTAT");
        assertEq(CMTATStandaloneERC7551(token).decimals(), 0);
        assertEq(CMTATStandaloneERC7551(token).tokenId(), "CMTAT_ISIN");
        assertEq(CMTATStandaloneERC7551(token).information(), "CMTAT_info");
        assertTrue(CMTATStandaloneERC7551(token).hasRole(DEFAULT_ADMIN_ROLE, ADMIN));
        assertTrue(CMTATStandaloneERC7551(token).isTrustedForwarder(FORWARDER));
    }

    function test_DeployStandaloneERC7551_Defaults() public {
        CMTATStandaloneERC7551 cmtat = standaloneDeployer.deploy(
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
        _assertCommon(address(cmtat));
    }

    function test_DeployUpgradeableERC7551Proxy_Defaults() public {
        CMTATUpgradeableERC7551 cmtat = proxyDeployer.deploy(
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
        _assertCommon(address(cmtat));
    }

    function test_RevertWhen_DeployERC7551WithZeroAdmin() public {
        vm.expectRevert();
        standaloneDeployer.deploy(address(0), FORWARDER, "N", "S", 0, "ID", "T", "U", "I");

        vm.expectRevert();
        proxyDeployer.deploy(address(0), FORWARDER, "N", "S", 0, "ID", "T", "U", "I");
    }
}
