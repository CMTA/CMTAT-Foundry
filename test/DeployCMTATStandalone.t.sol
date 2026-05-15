//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../script/DeployCMTATStandalone.s.sol";

contract DeployCMTATStandaloneTest is Test {
    DeployCMTATStandalone public deployer;

    address constant ADMIN = address(1);
    address constant FORWARDER = address(2);

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    function setUp() public {
        deployer = new DeployCMTATStandalone();
    }

    function test_DeployWithDefaultValues() public {
        CMTATStandalone cmtat = deployer.deploy(
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
    }

    function test_DeployWithCustomValues() public {
        string memory customName = "Custom Token";
        string memory customSymbol = "CTK";
        uint8 customDecimals = 18;
        string memory customTokenId = "CUSTOM_ID";
        string memory customTermsName = "Custom Terms";
        string memory customTermsUri = "https://example.com/terms";
        string memory customInfo = "Custom info";

        CMTATStandalone cmtat = deployer.deploy(
            ADMIN,
            address(0),
            customName,
            customSymbol,
            customDecimals,
            customTokenId,
            customTermsName,
            customTermsUri,
            customInfo
        );

        assertEq(cmtat.name(), customName);
        assertEq(cmtat.symbol(), customSymbol);
        assertEq(cmtat.decimals(), customDecimals);
        assertEq(cmtat.tokenId(), customTokenId);
        assertEq(cmtat.information(), customInfo);
    }

    function test_DeployWithForwarder() public {
        CMTATStandalone cmtat = deployer.deploy(
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

    function test_AdminHasAllRoles() public {
        CMTATStandalone cmtat = deployer.deploy(
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

        bytes32 minterRole = keccak256("MINTER_ROLE");
        bytes32 burnerRole = keccak256("BURNER_ROLE");
        bytes32 enforcerRole = keccak256("ENFORCER_ROLE");
        bytes32 pauserRole = keccak256("PAUSER_ROLE");

        assertTrue(cmtat.hasRole(DEFAULT_ADMIN_ROLE, ADMIN));
        assertTrue(cmtat.hasRole(minterRole, ADMIN));
        assertTrue(cmtat.hasRole(burnerRole, ADMIN));
        assertTrue(cmtat.hasRole(enforcerRole, ADMIN));
        assertTrue(cmtat.hasRole(pauserRole, ADMIN));
    }

    function test_InitialSupplyIsZero() public {
        CMTATStandalone cmtat = deployer.deploy(
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

        assertEq(cmtat.totalSupply(), 0);
    }

    function test_DeployedContractIsNotPaused() public {
        CMTATStandalone cmtat = deployer.deploy(
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

        assertFalse(cmtat.paused());
    }

    function test_Run_UsesEnvironmentOverrides() public {
        address envAdmin = address(0xA11CE);
        address envForwarder = address(0xF0);
        vm.setEnv("ADMIN_ADDRESS", vm.toString(envAdmin));
        vm.setEnv("FORWARDER_ADDRESS", vm.toString(envForwarder));
        vm.setEnv("TOKEN_NAME", "Env Token");
        vm.setEnv("TOKEN_SYMBOL", "ENV");
        vm.setEnv("TOKEN_DECIMALS", "6");
        vm.setEnv("TOKEN_ID", "ENV_ID");
        vm.setEnv("TERMS_NAME", "Env Terms");
        vm.setEnv("TERMS_URI", "https://env.example/terms");
        vm.setEnv("TOKEN_INFO", "env-info");

        CMTATStandalone cmtat = deployer.run();

        assertEq(cmtat.name(), "Env Token");
        assertEq(cmtat.symbol(), "ENV");
        assertEq(cmtat.decimals(), 6);
        assertEq(cmtat.tokenId(), "ENV_ID");
        assertEq(cmtat.information(), "env-info");
        assertTrue(cmtat.hasRole(DEFAULT_ADMIN_ROLE, envAdmin));
        assertTrue(cmtat.isTrustedForwarder(envForwarder));
    }

    function test_Run_UsesProvidedAdminEnvDeterministically() public {
        address envAdmin = address(0xCA11E2);
        vm.setEnv("ADMIN_ADDRESS", vm.toString(envAdmin));
        vm.setEnv("FORWARDER_ADDRESS", vm.toString(FORWARDER));
        vm.setEnv("TOKEN_NAME", "Sender Token");
        vm.setEnv("TOKEN_SYMBOL", "SND");
        vm.setEnv("TOKEN_DECIMALS", "4");
        vm.setEnv("TOKEN_ID", "SND_ID");
        vm.setEnv("TERMS_NAME", "Sender Terms");
        vm.setEnv("TERMS_URI", "https://sender.example/terms");
        vm.setEnv("TOKEN_INFO", "sender-info");

        CMTATStandalone cmtat = deployer.run();

        assertTrue(cmtat.hasRole(DEFAULT_ADMIN_ROLE, envAdmin));
        assertEq(cmtat.name(), "Sender Token");
        assertEq(cmtat.symbol(), "SND");
        assertEq(cmtat.decimals(), 4);
    }
}
