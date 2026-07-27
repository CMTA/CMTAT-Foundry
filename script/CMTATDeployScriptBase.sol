//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "CMTAT/interfaces/technical/ICMTATConstructor.sol";
import "CMTAT/interfaces/tokenization/draft-IERC1643CMTAT.sol";

abstract contract CMTATDeployScriptBase is Script {
    string public constant DEFAULT_NAME = "CMTA Token";
    string public constant DEFAULT_SYMBOL = "CMTAT";
    uint8 public constant DEFAULT_DECIMALS = 0;
    string public constant DEFAULT_TOKEN_ID = "CMTAT_ISIN";
    string public constant DEFAULT_TERMS_NAME = "Terms";
    string public constant DEFAULT_TERMS_URI = "https://cmta.ch/terms";
    string public constant DEFAULT_INFO = "CMTAT_info";

    struct LightParams {
        address admin;
        string name;
        string symbol;
        uint8 decimals;
    }

    struct ExtendedParams {
        address admin;
        address forwarder;
        string name;
        string symbol;
        uint8 decimals;
        string tokenId;
        string termsName;
        string termsUri;
        string info;
    }

    function _readLightParams() internal returns (LightParams memory p) {
        p.admin = vm.envOr("ADMIN_ADDRESS", msg.sender);
        p.name = vm.envOr("TOKEN_NAME", DEFAULT_NAME);
        p.symbol = vm.envOr("TOKEN_SYMBOL", DEFAULT_SYMBOL);
        p.decimals = uint8(vm.envOr("TOKEN_DECIMALS", uint256(DEFAULT_DECIMALS)));
    }

    function _readExtendedParams(bool withForwarder) internal returns (ExtendedParams memory p) {
        p.admin = vm.envOr("ADMIN_ADDRESS", msg.sender);
        p.forwarder = withForwarder ? vm.envOr("FORWARDER_ADDRESS", address(0)) : address(0);
        p.name = vm.envOr("TOKEN_NAME", DEFAULT_NAME);
        p.symbol = vm.envOr("TOKEN_SYMBOL", DEFAULT_SYMBOL);
        p.decimals = uint8(vm.envOr("TOKEN_DECIMALS", uint256(DEFAULT_DECIMALS)));
        p.tokenId = vm.envOr("TOKEN_ID", DEFAULT_TOKEN_ID);
        p.termsName = vm.envOr("TERMS_NAME", DEFAULT_TERMS_NAME);
        p.termsUri = vm.envOr("TERMS_URI", DEFAULT_TERMS_URI);
        p.info = vm.envOr("TOKEN_INFO", DEFAULT_INFO);
    }

    function _buildERC20Attributes(string memory name, string memory symbol, uint8 decimals)
        internal
        pure
        returns (ICMTATConstructor.ERC20Attributes memory)
    {
        return ICMTATConstructor.ERC20Attributes({name: name, symbol: symbol, decimalsIrrevocable: decimals});
    }

    function _buildExtraInformationAttributes(
        string memory tokenId,
        string memory termsName,
        string memory termsUri,
        string memory info
    ) internal pure returns (ICMTATConstructor.ExtraInformationAttributes memory) {
        IERC1643CMTAT.DocumentInfo memory termsDoc =
            IERC1643CMTAT.DocumentInfo({name: termsName, uri: termsUri, documentHash: bytes32(0)});
        return ICMTATConstructor.ExtraInformationAttributes({tokenId: tokenId, terms: termsDoc, information: info});
    }

    function _buildDefaultEngine() internal pure returns (ICMTATConstructor.Engine memory) {
        return ICMTATConstructor.Engine({ruleEngine: IRuleEngine(address(0))});
    }
}
