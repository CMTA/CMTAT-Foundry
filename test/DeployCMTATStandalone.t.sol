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
}
