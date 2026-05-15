//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import "CMTAT/interfaces/engine/ISnapshotEngine.sol";

contract MockSnapshotEngine is ISnapshotEngine {
    uint256 public calls;
    address public lastFrom;
    address public lastTo;
    uint256 public lastBalanceFrom;
    uint256 public lastBalanceTo;
    uint256 public lastTotalSupply;

    function operateOnTransfer(address from, address to, uint256 balanceFrom, uint256 balanceTo, uint256 totalSupply) external {
        calls += 1;
        lastFrom = from;
        lastTo = to;
        lastBalanceFrom = balanceFrom;
        lastBalanceTo = balanceTo;
        lastTotalSupply = totalSupply;
    }
}
