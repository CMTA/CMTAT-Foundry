//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../script/DeployCMTATStandaloneLight.s.sol";
import "../script/DeployCMTATUpgradeableLightProxy.s.sol";
import "../script/DeployCMTATStandaloneAllowlist.s.sol";
import "../script/DeployCMTATUpgradeableAllowlistProxy.s.sol";
import "../script/DeployCMTATStandaloneDebt.s.sol";
import "../script/DeployCMTATUpgradeableDebtProxy.s.sol";
import "../script/DeployCMTATStandaloneDebtEngine.s.sol";
import "../script/DeployCMTATUpgradeableDebtEngineProxy.s.sol";
import "../script/DeployCMTATStandaloneERC1363.s.sol";
import "../script/DeployCMTATUpgradeableERC1363Proxy.s.sol";
import "../script/DeployCMTATStandaloneERC7551.s.sol";
import "../script/DeployCMTATUpgradeableERC7551Proxy.s.sol";

contract DeployAdditionalScriptsRunTest is Test {
    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;
    address internal constant ENV_ADMIN = address(0xABCD);
    address internal constant ENV_FORWARDER = address(0xF0);

    function _setCommonEnv(string memory n, string memory s, string memory d) internal {
        vm.setEnv("ADMIN_ADDRESS", vm.toString(ENV_ADMIN));
        vm.setEnv("TOKEN_NAME", n);
        vm.setEnv("TOKEN_SYMBOL", s);
        vm.setEnv("TOKEN_DECIMALS", d);
    }

    function _setExtendedEnv() internal {
        vm.setEnv("TOKEN_ID", "ENV_ID");
        vm.setEnv("TERMS_NAME", "Env Terms");
        vm.setEnv("TERMS_URI", "https://env.example/terms");
        vm.setEnv("TOKEN_INFO", "env-info");
    }

    function test_Run_LightScriptsUseEnv() public {
        _setCommonEnv("LightEnv", "LGT", "3");
        CMTATStandaloneLight s = new DeployCMTATStandaloneLight().run();
        assertEq(s.name(), "LightEnv");
        assertEq(s.symbol(), "LGT");
        assertEq(s.decimals(), 3);
        assertTrue(s.hasRole(DEFAULT_ADMIN_ROLE, ENV_ADMIN));

        CMTATUpgradeableLight p = new DeployCMTATUpgradeableLightProxy().run();
        assertEq(p.name(), "LightEnv");
        assertEq(p.symbol(), "LGT");
        assertEq(p.decimals(), 3);
        assertTrue(p.hasRole(DEFAULT_ADMIN_ROLE, ENV_ADMIN));
    }

    function test_Run_ExtendedScriptsUseEnv() public {
        _setCommonEnv("ExtEnv", "EXT", "5");
        _setExtendedEnv();
        vm.setEnv("FORWARDER_ADDRESS", vm.toString(ENV_FORWARDER));

        CMTATStandaloneAllowlist a = new DeployCMTATStandaloneAllowlist().run();
        assertEq(a.name(), "ExtEnv");
        assertEq(a.tokenId(), "ENV_ID");
        assertTrue(a.isTrustedForwarder(ENV_FORWARDER));
        assertTrue(a.hasRole(DEFAULT_ADMIN_ROLE, ENV_ADMIN));

        CMTATUpgradeableAllowlist ap = new DeployCMTATUpgradeableAllowlistProxy().run();
        assertEq(ap.symbol(), "EXT");
        assertTrue(ap.isTrustedForwarder(ENV_FORWARDER));

        CMTATStandaloneDebt d = new DeployCMTATStandaloneDebt().run();
        assertEq(d.information(), "env-info");
        assertTrue(d.hasRole(DEFAULT_ADMIN_ROLE, ENV_ADMIN));

        CMTATUpgradeableDebt dp = new DeployCMTATUpgradeableDebtProxy().run();
        assertEq(dp.decimals(), 5);

        CMTATStandaloneDebtEngine de = new DeployCMTATStandaloneDebtEngine().run();
        assertEq(de.tokenId(), "ENV_ID");

        CMTATUpgradeableDebtEngine dep = new DeployCMTATUpgradeableDebtEngineProxy().run();
        assertEq(dep.symbol(), "EXT");

        CMTATStandaloneERC1363 e1363 = new DeployCMTATStandaloneERC1363().run();
        assertTrue(e1363.isTrustedForwarder(ENV_FORWARDER));

        CMTATUpgradeableERC1363 e1363p = new DeployCMTATUpgradeableERC1363Proxy().run();
        assertEq(e1363p.name(), "ExtEnv");

        CMTATStandaloneERC7551 e7551 = new DeployCMTATStandaloneERC7551().run();
        assertEq(e7551.information(), "env-info");

        CMTATUpgradeableERC7551 e7551p = new DeployCMTATUpgradeableERC7551Proxy().run();
        assertTrue(e7551p.isTrustedForwarder(ENV_FORWARDER));
    }
}
