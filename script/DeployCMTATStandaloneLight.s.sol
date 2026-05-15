//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "CMTAT/deployment/light/CMTATStandaloneLight.sol";
import "CMTAT/interfaces/technical/ICMTATConstructor.sol";

contract DeployCMTATStandaloneLight is Script {
    string public constant DEFAULT_NAME = "CMTA Token";
    string public constant DEFAULT_SYMBOL = "CMTAT";
    uint8 public constant DEFAULT_DECIMALS = 0;

    function run() external returns (CMTATStandaloneLight) {
        address admin = vm.envOr("ADMIN_ADDRESS", msg.sender);
        string memory name = vm.envOr("TOKEN_NAME", DEFAULT_NAME);
        string memory symbol = vm.envOr("TOKEN_SYMBOL", DEFAULT_SYMBOL);
        uint8 decimals = uint8(vm.envOr("TOKEN_DECIMALS", uint256(DEFAULT_DECIMALS)));

        vm.startBroadcast();
        CMTATStandaloneLight cmtat = deploy(admin, name, symbol, decimals);
        vm.stopBroadcast();
        return cmtat;
    }

    function deploy(address admin, string memory name, string memory symbol, uint8 decimals)
        public
        returns (CMTATStandaloneLight)
    {
        ICMTATConstructor.ERC20Attributes memory erc20Attributes = ICMTATConstructor.ERC20Attributes({
            name: name,
            symbol: symbol,
            decimalsIrrevocable: decimals
        });
        return new CMTATStandaloneLight(admin, erc20Attributes);
    }
}
