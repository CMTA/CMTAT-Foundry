//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import "CMTAT/interfaces/engine/IRuleEngine.sol";

contract MockRuleEngine is IRuleEngine {
    bool public allowCanTransfer = true;
    bool public allowCanTransferFrom = true;
    bool public revertOnTransferred;

    error MockRuleEngine_TransferRejected();

    function setAllowCanTransfer(bool allowed) external {
        allowCanTransfer = allowed;
    }

    function setAllowCanTransferFrom(bool allowed) external {
        allowCanTransferFrom = allowed;
    }

    function setRevertOnTransferred(bool shouldRevert) external {
        revertOnTransferred = shouldRevert;
    }

    function canTransfer(address, address, uint256) external view returns (bool) {
        return allowCanTransfer;
    }

    function canTransferFrom(address, address, address, uint256) external view returns (bool) {
        return allowCanTransferFrom;
    }

    function transferred(address, address, uint256) external view {
        if (revertOnTransferred) {
            revert MockRuleEngine_TransferRejected();
        }
    }

    function transferred(address, address, address, uint256) external view {
        if (revertOnTransferred) {
            revert MockRuleEngine_TransferRejected();
        }
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IRuleEngine).interfaceId;
    }
}
