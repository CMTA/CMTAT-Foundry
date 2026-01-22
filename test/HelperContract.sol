//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "CMTAT/deployment/CMTATStandalone.sol";
import "CMTAT/interfaces/technical/ICMTATConstructor.sol";
import "CMTAT/interfaces/tokenization/draft-IERC1643CMTAT.sol";

abstract contract HelperContract is Test {
    CMTATStandalone public cmtat;

    // Addresses
    address constant ZERO_ADDRESS = address(0);
    address constant ADMIN = address(1);
    address constant USER1 = address(2);
    address constant USER2 = address(3);
    address constant USER3 = address(4);

    // Role hashes
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant ENFORCER_ROLE = keccak256("ENFORCER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // Token attributes
    string constant TOKEN_NAME = "CMTA Token";
    string constant TOKEN_SYMBOL = "CMTAT";
    uint8 constant TOKEN_DECIMALS = 0;
    string constant TOKEN_ID = "CMTAT_ISIN";
    string constant TOKEN_TERMS_NAME = "Terms";
    string constant TOKEN_TERMS_URI = "https://cmta.ch/terms";
    bytes32 constant TOKEN_TERMS_HASH = bytes32(0);
    string constant TOKEN_INFO = "CMTAT_info";

    function _deployToken() internal {
        // Create ERC20 attributes
        ICMTATConstructor.ERC20Attributes memory erc20Attributes = ICMTATConstructor.ERC20Attributes({
            name: TOKEN_NAME, symbol: TOKEN_SYMBOL, decimalsIrrevocable: TOKEN_DECIMALS
        });

        // Create document info for terms
        IERC1643CMTAT.DocumentInfo memory termsDoc =
            IERC1643CMTAT.DocumentInfo({name: TOKEN_TERMS_NAME, uri: TOKEN_TERMS_URI, documentHash: TOKEN_TERMS_HASH});

        // Create extra information attributes
        ICMTATConstructor.ExtraInformationAttributes memory extraInfoAttributes =
            ICMTATConstructor.ExtraInformationAttributes({tokenId: TOKEN_ID, terms: termsDoc, information: TOKEN_INFO});

        // Create engine struct (no rule engine for basic tests)
        ICMTATConstructor.Engine memory engines = ICMTATConstructor.Engine({ruleEngine: IRuleEngine(ZERO_ADDRESS)});

        // Deploy the contract
        vm.prank(ADMIN);
        cmtat = new CMTATStandalone(
            ZERO_ADDRESS, // forwarderIrrevocable
            ADMIN, // admin
            erc20Attributes,
            extraInfoAttributes,
            engines
        );
    }
}
