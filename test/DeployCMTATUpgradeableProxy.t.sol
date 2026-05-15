//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../script/DeployCMTATUpgradeableProxy.s.sol";
import "../script/DeployCMTATUpgradeableUUPSProxy.s.sol";

contract DeployCMTATUpgradeableProxyTest is Test {
    DeployCMTATUpgradeableProxy public deployer;

    address constant ADMIN = address(1);
    address constant FORWARDER = address(2);

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant PROXY_UPGRADE_ROLE = keccak256("PROXY_UPGRADE_ROLE");

    function setUp() public {
        deployer = new DeployCMTATUpgradeableProxy();
    }

    function test_DeployUpgradeableProxyWithDefaultValues() public {
        CMTATUpgradeable cmtat = deployer.deploy(
            ADMIN,
            address(0),
            deployer.DEFAULT_NAME(),
            deployer.DEFAULT_SYMBOL(),
            deployer.DEFAULT_DECIMALS(),
            deployer.DEFAULT_TOKEN_ID(),
            deployer.DEFAULT_TERMS_NAME(),
            deployer.DEFAULT_TERMS_URI(),
            deployer.DEFAULT_INFO()
        );

        assertEq(cmtat.name(), "CMTA Token");
        assertEq(cmtat.symbol(), "CMTAT");
        assertEq(cmtat.decimals(), 0);
        assertEq(cmtat.tokenId(), "CMTAT_ISIN");
        assertEq(cmtat.information(), "CMTAT_info");
        assertTrue(cmtat.hasRole(DEFAULT_ADMIN_ROLE, ADMIN));
    }

    function test_DeployUpgradeableProxyWithForwarder() public {
        CMTATUpgradeable cmtat = deployer.deploy(
            ADMIN,
            FORWARDER,
            deployer.DEFAULT_NAME(),
            deployer.DEFAULT_SYMBOL(),
            deployer.DEFAULT_DECIMALS(),
            deployer.DEFAULT_TOKEN_ID(),
            deployer.DEFAULT_TERMS_NAME(),
            deployer.DEFAULT_TERMS_URI(),
            deployer.DEFAULT_INFO()
        );
        assertTrue(cmtat.isTrustedForwarder(FORWARDER));
    }
}

contract DeployCMTATUpgradeableUUPSProxyTest is Test {
    DeployCMTATUpgradeableUUPSProxy public deployer;

    address constant ADMIN = address(1);
    address constant FORWARDER = address(2);

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant PROXY_UPGRADE_ROLE = keccak256("PROXY_UPGRADE_ROLE");

    function setUp() public {
        deployer = new DeployCMTATUpgradeableUUPSProxy();
    }

    function test_DeployUUPSProxyWithDefaultValues() public {
        CMTATUpgradeableUUPS cmtat = deployer.deploy(
            ADMIN,
            address(0),
            deployer.DEFAULT_NAME(),
            deployer.DEFAULT_SYMBOL(),
            deployer.DEFAULT_DECIMALS(),
            deployer.DEFAULT_TOKEN_ID(),
            deployer.DEFAULT_TERMS_NAME(),
            deployer.DEFAULT_TERMS_URI(),
            deployer.DEFAULT_INFO()
        );

        assertEq(cmtat.name(), "CMTA Token");
        assertEq(cmtat.symbol(), "CMTAT");
        assertEq(cmtat.decimals(), 0);
        assertTrue(cmtat.hasRole(DEFAULT_ADMIN_ROLE, ADMIN));
        assertTrue(cmtat.hasRole(PROXY_UPGRADE_ROLE, ADMIN));
    }

    function test_DeployUUPSProxyWithForwarder() public {
        CMTATUpgradeableUUPS cmtat = deployer.deploy(
            ADMIN,
            FORWARDER,
            deployer.DEFAULT_NAME(),
            deployer.DEFAULT_SYMBOL(),
            deployer.DEFAULT_DECIMALS(),
            deployer.DEFAULT_TOKEN_ID(),
            deployer.DEFAULT_TERMS_NAME(),
            deployer.DEFAULT_TERMS_URI(),
            deployer.DEFAULT_INFO()
        );
        assertTrue(cmtat.isTrustedForwarder(FORWARDER));
    }
}
