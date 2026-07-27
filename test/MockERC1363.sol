//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/interfaces/IERC1363Receiver.sol";
import "@openzeppelin/contracts/interfaces/IERC1363Spender.sol";

/// @dev Accepts the callback and records what it was called with.
contract MockERC1363Receiver is IERC1363Receiver {
    event TokensReceived(address operator, address from, uint256 value, bytes data);

    address public lastOperator;
    address public lastFrom;
    uint256 public lastValue;
    bytes public lastData;

    function onTransferReceived(address operator, address from, uint256 value, bytes calldata data)
        external
        override
        returns (bytes4)
    {
        lastOperator = operator;
        lastFrom = from;
        lastValue = value;
        lastData = data;
        emit TokensReceived(operator, from, value, data);
        return IERC1363Receiver.onTransferReceived.selector;
    }
}

/// @dev Returns a wrong selector, which the ERC-1363 caller must treat as a rejection.
contract MockERC1363RejectingReceiver is IERC1363Receiver {
    function onTransferReceived(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return bytes4(0xdeadbeef);
    }
}

/// @dev Accepts `approveAndCall` and records what it was called with.
contract MockERC1363Spender is IERC1363Spender {
    address public lastOwner;
    uint256 public lastValue;
    bytes public lastData;

    function onApprovalReceived(address owner, uint256 value, bytes calldata data) external override returns (bytes4) {
        lastOwner = owner;
        lastValue = value;
        lastData = data;
        return IERC1363Spender.onApprovalReceived.selector;
    }
}
