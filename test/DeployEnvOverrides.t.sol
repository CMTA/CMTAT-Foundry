//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../script/DeployCMTATStandalone.s.sol";
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

/// @dev `vm.setEnv` mutates the environment of the whole forge process, while forge runs test
///      cases in parallel. Any two test functions setting the same variable therefore race with
///      each other. All coverage of the scripts' `run()` (i.e. env-driven) path is consequently
///      kept in this single test function — the only place in the suite allowed to call
///      `vm.setEnv`. Every other deployment test must call `deploy(...)` with explicit arguments.
contract DeployEnvOverridesTest is Test {
    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;
    address internal constant ENV_ADMIN = address(0xABCD);
    address internal constant ENV_FORWARDER = address(0xF0);

    function _setCommonEnv(string memory name, string memory symbol, string memory decimals) internal {
        vm.setEnv("ADMIN_ADDRESS", vm.toString(ENV_ADMIN));
        vm.setEnv("TOKEN_NAME", name);
        vm.setEnv("TOKEN_SYMBOL", symbol);
        vm.setEnv("TOKEN_DECIMALS", decimals);
    }

    function _setExtendedEnv() internal {
        vm.setEnv("FORWARDER_ADDRESS", vm.toString(ENV_FORWARDER));
        vm.setEnv("TOKEN_ID", "ENV_ID");
        vm.setEnv("TERMS_NAME", "Env Terms");
        vm.setEnv("TERMS_URI", "https://env.example/terms");
        vm.setEnv("TOKEN_INFO", "env-info");
    }

    function test_Run_ScriptsUseEnvironmentOverrides() public {
        _runBaseStandalone();
        _runLightScripts();
        _runExtendedScripts();
    }

    /// @dev Base `CMTATStandalone`: full attribute set plus the trusted forwarder.
    function _runBaseStandalone() internal {
        _setCommonEnv("Env Token", "ENV", "6");
        _setExtendedEnv();

        CMTATStandalone cmtat = new DeployCMTATStandalone().run();
        assertEq(cmtat.name(), "Env Token");
        assertEq(cmtat.symbol(), "ENV");
        assertEq(cmtat.decimals(), 6);
        assertEq(cmtat.tokenId(), "ENV_ID");
        assertEq(cmtat.information(), "env-info");
        assertTrue(cmtat.hasRole(DEFAULT_ADMIN_ROLE, ENV_ADMIN));
        assertTrue(cmtat.isTrustedForwarder(ENV_FORWARDER));
    }

    /// @dev Light variants read only the ERC20 attributes and the admin.
    function _runLightScripts() internal {
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

    /// @dev Allowlist / debt / debtEngine / ERC1363 / ERC7551, standalone and proxy.
    function _runExtendedScripts() internal {
        _setCommonEnv("ExtEnv", "EXT", "5");
        _setExtendedEnv();

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
