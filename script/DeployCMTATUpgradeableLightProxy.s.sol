//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import "./CMTATDeployScriptBase.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "CMTAT/deployment/light/CMTATUpgradeableLight.sol";
import "CMTAT/interfaces/technical/ICMTATConstructor.sol";

interface ICMTATLightInitializer {
    function initialize(address admin, ICMTATConstructor.ERC20Attributes memory ERC20Attributes_) external;
}

contract DeployCMTATUpgradeableLightProxy is CMTATDeployScriptBase {

    function run() external returns (CMTATUpgradeableLight) {
        LightParams memory p = _readLightParams();

        vm.startBroadcast();
        CMTATUpgradeableLight cmtat = deploy(p.admin, p.name, p.symbol, p.decimals);
        vm.stopBroadcast();
        return cmtat;
    }

    function deploy(address admin, string memory name, string memory symbol, uint8 decimals)
        public
        returns (CMTATUpgradeableLight)
    {
        CMTATUpgradeableLight implementation = new CMTATUpgradeableLight();
        ICMTATConstructor.ERC20Attributes memory erc20Attributes = _buildERC20Attributes(name, symbol, decimals);
        bytes memory initData = abi.encodeCall(ICMTATLightInitializer.initialize, (admin, erc20Attributes));
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        return CMTATUpgradeableLight(address(proxy));
    }
}
