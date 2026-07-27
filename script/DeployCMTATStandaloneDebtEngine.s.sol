//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import "./CMTATDeployScriptBase.sol";
import "CMTAT/deployment/debtEngine/CMTATStandaloneDebtEngine.sol";
import "CMTAT/interfaces/technical/ICMTATConstructor.sol";

contract DeployCMTATStandaloneDebtEngine is CMTATDeployScriptBase {

    function run() external returns (CMTATStandaloneDebtEngine) {
        ExtendedParams memory p = _readExtendedParams(false);

        vm.startBroadcast();
        CMTATStandaloneDebtEngine cmtat =
            deploy(p.admin, p.name, p.symbol, p.decimals, p.tokenId, p.termsName, p.termsUri, p.info);
        vm.stopBroadcast();
        return cmtat;
    }

    function deploy(
        address admin,
        string memory name,
        string memory symbol,
        uint8 decimals,
        string memory tokenId,
        string memory termsName,
        string memory termsUri,
        string memory info
    ) public returns (CMTATStandaloneDebtEngine) {
        ICMTATConstructor.ERC20Attributes memory erc20Attributes = _buildERC20Attributes(name, symbol, decimals);
        ICMTATConstructor.ExtraInformationAttributes memory extraInfoAttributes =
            _buildExtraInformationAttributes(tokenId, termsName, termsUri, info);
        ICMTATConstructor.Engine memory engines = _buildDefaultEngine();
        return new CMTATStandaloneDebtEngine(admin, erc20Attributes, extraInfoAttributes, engines);
    }
}
