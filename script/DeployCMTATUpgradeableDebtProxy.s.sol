//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import "./CMTATDeployScriptBase.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "CMTAT/deployment/debt/CMTATUpgradeableDebt.sol";
import "CMTAT/interfaces/technical/ICMTATConstructor.sol";

interface ICMTATDebtInitializer {
    function initialize(
        address admin,
        ICMTATConstructor.ERC20Attributes memory ERC20Attributes_,
        ICMTATConstructor.ExtraInformationAttributes memory extraInformationAttributes_,
        ICMTATConstructor.Engine memory engines_
    ) external;
}

contract DeployCMTATUpgradeableDebtProxy is CMTATDeployScriptBase {

    function run() external returns (CMTATUpgradeableDebt) {
        ExtendedParams memory p = _readExtendedParams(false);

        vm.startBroadcast();
        CMTATUpgradeableDebt cmtat =
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
    ) public returns (CMTATUpgradeableDebt) {
        CMTATUpgradeableDebt implementation = new CMTATUpgradeableDebt();
        ICMTATConstructor.ERC20Attributes memory erc20Attributes = _buildERC20Attributes(name, symbol, decimals);
        ICMTATConstructor.ExtraInformationAttributes memory extraInfoAttributes =
            _buildExtraInformationAttributes(tokenId, termsName, termsUri, info);
        ICMTATConstructor.Engine memory engines = _buildDefaultEngine();
        bytes memory initData = abi.encodeCall(
            ICMTATDebtInitializer.initialize, (admin, erc20Attributes, extraInfoAttributes, engines)
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        return CMTATUpgradeableDebt(address(proxy));
    }
}
