//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "CMTAT/deployment/ERC1363/CMTATUpgradeableERC1363.sol";
import "CMTAT/interfaces/technical/ICMTATConstructor.sol";
import "CMTAT/interfaces/tokenization/draft-IERC1643CMTAT.sol";

interface ICMTATERC1363Initializer {
    function initialize(
        address admin,
        ICMTATConstructor.ERC20Attributes memory ERC20Attributes_,
        ICMTATConstructor.ExtraInformationAttributes memory extraInformationAttributes_,
        ICMTATConstructor.Engine memory engines_
    ) external;
}

contract DeployCMTATUpgradeableERC1363Proxy is Script {
    string public constant DEFAULT_NAME = "CMTA Token";
    string public constant DEFAULT_SYMBOL = "CMTAT";
    uint8 public constant DEFAULT_DECIMALS = 0;
    string public constant DEFAULT_TOKEN_ID = "CMTAT_ISIN";
    string public constant DEFAULT_TERMS_NAME = "Terms";
    string public constant DEFAULT_TERMS_URI = "https://cmta.ch/terms";
    string public constant DEFAULT_INFO = "CMTAT_info";

    function run() external returns (CMTATUpgradeableERC1363) {
        address admin = vm.envOr("ADMIN_ADDRESS", msg.sender);
        address forwarder = vm.envOr("FORWARDER_ADDRESS", address(0));
        string memory name = vm.envOr("TOKEN_NAME", DEFAULT_NAME);
        string memory symbol = vm.envOr("TOKEN_SYMBOL", DEFAULT_SYMBOL);
        uint8 decimals = uint8(vm.envOr("TOKEN_DECIMALS", uint256(DEFAULT_DECIMALS)));
        string memory tokenId = vm.envOr("TOKEN_ID", DEFAULT_TOKEN_ID);
        string memory termsName = vm.envOr("TERMS_NAME", DEFAULT_TERMS_NAME);
        string memory termsUri = vm.envOr("TERMS_URI", DEFAULT_TERMS_URI);
        string memory info = vm.envOr("TOKEN_INFO", DEFAULT_INFO);

        vm.startBroadcast();
        CMTATUpgradeableERC1363 cmtat =
            deploy(admin, forwarder, name, symbol, decimals, tokenId, termsName, termsUri, info);
        vm.stopBroadcast();
        return cmtat;
    }

    function deploy(
        address admin,
        address forwarder,
        string memory name,
        string memory symbol,
        uint8 decimals,
        string memory tokenId,
        string memory termsName,
        string memory termsUri,
        string memory info
    ) public returns (CMTATUpgradeableERC1363) {
        CMTATUpgradeableERC1363 implementation = new CMTATUpgradeableERC1363(forwarder);
        ICMTATConstructor.ERC20Attributes memory erc20Attributes = ICMTATConstructor.ERC20Attributes({
            name: name,
            symbol: symbol,
            decimalsIrrevocable: decimals
        });
        IERC1643CMTAT.DocumentInfo memory termsDoc = IERC1643CMTAT.DocumentInfo({
            name: termsName,
            uri: termsUri,
            documentHash: bytes32(0)
        });
        ICMTATConstructor.ExtraInformationAttributes memory extraInfoAttributes = ICMTATConstructor
            .ExtraInformationAttributes({tokenId: tokenId, terms: termsDoc, information: info});
        ICMTATConstructor.Engine memory engines = ICMTATConstructor.Engine({ruleEngine: IRuleEngine(address(0))});
        bytes memory initData = abi.encodeCall(
            ICMTATERC1363Initializer.initialize, (admin, erc20Attributes, extraInfoAttributes, engines)
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        return CMTATUpgradeableERC1363(address(proxy));
    }
}
