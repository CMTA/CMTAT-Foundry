//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../script/DeployCMTATStandaloneDebt.s.sol";
import "../script/DeployCMTATUpgradeableDebtProxy.s.sol";
import "../script/DeployCMTATStandaloneDebtEngine.s.sol";
import "../script/DeployCMTATUpgradeableDebtEngineProxy.s.sol";

abstract contract DeployDebtBase is Test {
    address internal constant ADMIN = address(1);
    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;

    function _assertCommon(address token) internal {
        assertEq(CMTATStandaloneDebt(token).name(), "CMTA Token");
        assertEq(CMTATStandaloneDebt(token).symbol(), "CMTAT");
        assertEq(CMTATStandaloneDebt(token).decimals(), 0);
        assertEq(CMTATStandaloneDebt(token).tokenId(), "CMTAT_ISIN");
        assertEq(CMTATStandaloneDebt(token).information(), "CMTAT_info");
        assertTrue(CMTATStandaloneDebt(token).hasRole(DEFAULT_ADMIN_ROLE, ADMIN));
    }
}

contract DeployCMTATDebtVersionsTest is DeployDebtBase {
    DeployCMTATStandaloneDebt internal standaloneDeployer;
    DeployCMTATUpgradeableDebtProxy internal proxyDeployer;

    function setUp() public {
        standaloneDeployer = new DeployCMTATStandaloneDebt();
        proxyDeployer = new DeployCMTATUpgradeableDebtProxy();
    }

    function test_DeployStandaloneDebt_Defaults() public {
        CMTATStandaloneDebt cmtat = standaloneDeployer.deploy(
            ADMIN,
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

    function test_DeployUpgradeableDebtProxy_Defaults() public {
        CMTATUpgradeableDebt cmtat = proxyDeployer.deploy(
            ADMIN,
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

    function test_RevertWhen_DeployDebtWithZeroAdmin() public {
        vm.expectRevert();
        standaloneDeployer.deploy(address(0), "N", "S", 0, "ID", "T", "U", "I");

        vm.expectRevert();
        proxyDeployer.deploy(address(0), "N", "S", 0, "ID", "T", "U", "I");
    }
}

contract DeployCMTATDebtEngineVersionsTest is DeployDebtBase {
    DeployCMTATStandaloneDebtEngine internal standaloneDeployer;
    DeployCMTATUpgradeableDebtEngineProxy internal proxyDeployer;

    function setUp() public {
        standaloneDeployer = new DeployCMTATStandaloneDebtEngine();
        proxyDeployer = new DeployCMTATUpgradeableDebtEngineProxy();
    }

    function test_DeployStandaloneDebtEngine_Defaults() public {
        CMTATStandaloneDebtEngine cmtat = standaloneDeployer.deploy(
            ADMIN,
            standaloneDeployer.DEFAULT_NAME(),
            standaloneDeployer.DEFAULT_SYMBOL(),
            standaloneDeployer.DEFAULT_DECIMALS(),
            standaloneDeployer.DEFAULT_TOKEN_ID(),
            standaloneDeployer.DEFAULT_TERMS_NAME(),
            standaloneDeployer.DEFAULT_TERMS_URI(),
            standaloneDeployer.DEFAULT_INFO()
        );
        _assertCommon(address(cmtat));
        assertEq(address(cmtat.debtEngine()), address(0));
    }

    function test_DeployUpgradeableDebtEngineProxy_Defaults() public {
        CMTATUpgradeableDebtEngine cmtat = proxyDeployer.deploy(
            ADMIN,
            proxyDeployer.DEFAULT_NAME(),
            proxyDeployer.DEFAULT_SYMBOL(),
            proxyDeployer.DEFAULT_DECIMALS(),
            proxyDeployer.DEFAULT_TOKEN_ID(),
            proxyDeployer.DEFAULT_TERMS_NAME(),
            proxyDeployer.DEFAULT_TERMS_URI(),
            proxyDeployer.DEFAULT_INFO()
        );
        _assertCommon(address(cmtat));
        assertEq(address(cmtat.debtEngine()), address(0));
    }

    function test_RevertWhen_DeployDebtEngineWithZeroAdmin() public {
        vm.expectRevert();
        standaloneDeployer.deploy(address(0), "N", "S", 0, "ID", "T", "U", "I");

        vm.expectRevert();
        proxyDeployer.deploy(address(0), "N", "S", 0, "ID", "T", "U", "I");
    }
}
