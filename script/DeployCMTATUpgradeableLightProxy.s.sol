//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "CMTAT/deployment/light/CMTATUpgradeableLight.sol";
import "CMTAT/interfaces/technical/ICMTATConstructor.sol";

interface ICMTATLightInitializer {
    function initialize(address admin, ICMTATConstructor.ERC20Attributes memory ERC20Attributes_) external;
}

contract DeployCMTATUpgradeableLightProxy is Script {
    string public constant DEFAULT_NAME = "CMTA Token";
    string public constant DEFAULT_SYMBOL = "CMTAT";
    uint8 public constant DEFAULT_DECIMALS = 0;

    function run() external returns (CMTATUpgradeableLight) {
        address admin = vm.envOr("ADMIN_ADDRESS", msg.sender);
        string memory name = vm.envOr("TOKEN_NAME", DEFAULT_NAME);
        string memory symbol = vm.envOr("TOKEN_SYMBOL", DEFAULT_SYMBOL);
        uint8 decimals = uint8(vm.envOr("TOKEN_DECIMALS", uint256(DEFAULT_DECIMALS)));

        vm.startBroadcast();
        CMTATUpgradeableLight cmtat = deploy(admin, name, symbol, decimals);
        vm.stopBroadcast();
        return cmtat;
    }

    function deploy(address admin, string memory name, string memory symbol, uint8 decimals)
        public
        returns (CMTATUpgradeableLight)
    {
        CMTATUpgradeableLight implementation = new CMTATUpgradeableLight();
        ICMTATConstructor.ERC20Attributes memory erc20Attributes = ICMTATConstructor.ERC20Attributes({
            name: name,
            symbol: symbol,
            decimalsIrrevocable: decimals
        });
        bytes memory initData = abi.encodeCall(ICMTATLightInitializer.initialize, (admin, erc20Attributes));
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        return CMTATUpgradeableLight(address(proxy));
    }
}
