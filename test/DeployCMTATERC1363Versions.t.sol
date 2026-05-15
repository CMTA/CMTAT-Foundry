//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../script/DeployCMTATStandaloneERC1363.s.sol";
import "../script/DeployCMTATUpgradeableERC1363Proxy.s.sol";
import "@openzeppelin/contracts/interfaces/IERC1363Receiver.sol";

contract ERC1363ReceiverMock is IERC1363Receiver {
    function onTransferReceived(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC1363Receiver.onTransferReceived.selector;
    }
}

abstract contract DeployERC1363Base is Test {
    address internal constant ADMIN = address(1);
    address internal constant FORWARDER = address(2);
    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes4 internal constant IERC1363_INTERFACEID = 0xb0202a11;

    function _assertCommon(address token) internal {
        assertEq(CMTATStandaloneERC1363(token).name(), "CMTA Token");
        assertEq(CMTATStandaloneERC1363(token).symbol(), "CMTAT");
        assertEq(CMTATStandaloneERC1363(token).decimals(), 0);
        assertEq(CMTATStandaloneERC1363(token).tokenId(), "CMTAT_ISIN");
        assertEq(CMTATStandaloneERC1363(token).information(), "CMTAT_info");
        assertTrue(CMTATStandaloneERC1363(token).hasRole(DEFAULT_ADMIN_ROLE, ADMIN));
        assertTrue(CMTATStandaloneERC1363(token).supportsInterface(IERC1363_INTERFACEID));
    }

    function _assertTransferAndCall(address token) internal {
        ERC1363ReceiverMock receiver = new ERC1363ReceiverMock();
        vm.prank(ADMIN);
        CMTATStandaloneERC1363(token).mint(ADMIN, 20);
        vm.prank(ADMIN);
        bool success = CMTATStandaloneERC1363(token).transferAndCall(address(receiver), 10);
        assertTrue(success);
        assertEq(CMTATStandaloneERC1363(token).balanceOf(address(receiver)), 10);
    }
}

contract DeployCMTATERC1363VersionsTest is DeployERC1363Base {
    DeployCMTATStandaloneERC1363 internal standaloneDeployer;
    DeployCMTATUpgradeableERC1363Proxy internal proxyDeployer;

    function setUp() public {
        standaloneDeployer = new DeployCMTATStandaloneERC1363();
        proxyDeployer = new DeployCMTATUpgradeableERC1363Proxy();
    }

    function test_DeployStandaloneERC1363_DefaultsForwarderAndTransferAndCall() public {
        CMTATStandaloneERC1363 cmtat = standaloneDeployer.deploy(
            ADMIN,
            FORWARDER,
            standaloneDeployer.DEFAULT_NAME(),
            standaloneDeployer.DEFAULT_SYMBOL(),
            standaloneDeployer.DEFAULT_DECIMALS(),
            standaloneDeployer.DEFAULT_TOKEN_ID(),
            standaloneDeployer.DEFAULT_TERMS_NAME(),
            standaloneDeployer.DEFAULT_TERMS_URI(),
            standaloneDeployer.DEFAULT_INFO()
        );
        _assertCommon(address(cmtat));
        assertTrue(cmtat.isTrustedForwarder(FORWARDER));
        _assertTransferAndCall(address(cmtat));
    }

    function test_DeployUpgradeableERC1363Proxy_DefaultsForwarderAndTransferAndCall() public {
        CMTATUpgradeableERC1363 cmtat = proxyDeployer.deploy(
            ADMIN,
            FORWARDER,
            proxyDeployer.DEFAULT_NAME(),
            proxyDeployer.DEFAULT_SYMBOL(),
            proxyDeployer.DEFAULT_DECIMALS(),
            proxyDeployer.DEFAULT_TOKEN_ID(),
            proxyDeployer.DEFAULT_TERMS_NAME(),
            proxyDeployer.DEFAULT_TERMS_URI(),
            proxyDeployer.DEFAULT_INFO()
        );
        _assertCommon(address(cmtat));
        assertTrue(cmtat.isTrustedForwarder(FORWARDER));
        _assertTransferAndCall(address(cmtat));
    }
}
