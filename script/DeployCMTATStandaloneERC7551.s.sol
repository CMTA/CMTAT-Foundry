//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import "./CMTATDeployScriptBase.sol";
import "CMTAT/deployment/ERC7551/CMTATStandaloneERC7551.sol";
import "CMTAT/interfaces/technical/ICMTATConstructor.sol";

contract DeployCMTATStandaloneERC7551 is CMTATDeployScriptBase {

    function run() external returns (CMTATStandaloneERC7551) {
        ExtendedParams memory p = _readExtendedParams(true);

        vm.startBroadcast();
        CMTATStandaloneERC7551 cmtat =
            deploy(p.admin, p.forwarder, p.name, p.symbol, p.decimals, p.tokenId, p.termsName, p.termsUri, p.info);
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
    ) public returns (CMTATStandaloneERC7551) {
        ICMTATConstructor.ERC20Attributes memory erc20Attributes = _buildERC20Attributes(name, symbol, decimals);
        ICMTATConstructor.ExtraInformationAttributes memory extraInfoAttributes =
            _buildExtraInformationAttributes(tokenId, termsName, termsUri, info);
        ICMTATConstructor.Engine memory engines = _buildDefaultEngine();
        return new CMTATStandaloneERC7551(forwarder, admin, erc20Attributes, extraInfoAttributes, engines);
    }
}
