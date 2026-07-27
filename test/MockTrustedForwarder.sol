//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

contract MockTrustedForwarder {
    function forward(address target, bytes calldata data, address signer) external returns (bytes memory) {
        (bool ok, bytes memory ret) = target.call(abi.encodePacked(data, signer));
        require(ok, "FORWARD_CALL_FAILED");
        return ret;
    }
}
