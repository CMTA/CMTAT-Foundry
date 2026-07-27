//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import "./CMTATDeployScriptBase.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "CMTAT/deployment/allowlist/CMTATUpgradeableAllowlist.sol";
import "CMTAT/interfaces/technical/ICMTATConstructor.sol";

interface ICMTATAllowlistInitializer {
    function initialize(
        address admin,
        ICMTATConstructor.ERC20Attributes memory ERC20Attributes_,
        ICMTATConstructor.ExtraInformationAttributes memory extraInformationAttributes_
    ) external;
}

contract DeployCMTATUpgradeableAllowlistProxy is CMTATDeployScriptBase {

    function run() external returns (CMTATUpgradeableAllowlist) {
        ExtendedParams memory p = _readExtendedParams(true);

        vm.startBroadcast();
        CMTATUpgradeableAllowlist cmtat =
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
    ) public returns (CMTATUpgradeableAllowlist) {
        CMTATUpgradeableAllowlist implementation = new CMTATUpgradeableAllowlist(forwarder);
        ICMTATConstructor.ERC20Attributes memory erc20Attributes = _buildERC20Attributes(name, symbol, decimals);
        ICMTATConstructor.ExtraInformationAttributes memory extraInfoAttributes =
            _buildExtraInformationAttributes(tokenId, termsName, termsUri, info);
        bytes memory initData = abi.encodeCall(
            ICMTATAllowlistInitializer.initialize, (admin, erc20Attributes, extraInfoAttributes)
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        return CMTATUpgradeableAllowlist(address(proxy));
    }
}
