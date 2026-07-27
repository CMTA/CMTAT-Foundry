//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import "./CMTATDeployScriptBase.sol";
import "CMTAT/deployment/light/CMTATStandaloneLight.sol";
import "CMTAT/interfaces/technical/ICMTATConstructor.sol";

contract DeployCMTATStandaloneLight is CMTATDeployScriptBase {

    function run() external returns (CMTATStandaloneLight) {
        LightParams memory p = _readLightParams();

        vm.startBroadcast();
        CMTATStandaloneLight cmtat = deploy(p.admin, p.name, p.symbol, p.decimals);
        vm.stopBroadcast();
        return cmtat;
    }

    function deploy(address admin, string memory name, string memory symbol, uint8 decimals)
        public
        returns (CMTATStandaloneLight)
    {
        ICMTATConstructor.ERC20Attributes memory erc20Attributes = _buildERC20Attributes(name, symbol, decimals);
        return new CMTATStandaloneLight(admin, erc20Attributes);
    }
}
