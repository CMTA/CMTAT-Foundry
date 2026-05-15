//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/StdInvariant.sol";
import "forge-std/Vm.sol";
import "./HelperContract.sol";

contract CMTATFuzzTest is HelperContract {
    bytes32 public constant ERC20ENFORCER_ROLE = keccak256("ERC20ENFORCER_ROLE");

    function setUp() public {
        _deployToken();
        vm.startPrank(ADMIN);
        cmtat.mint(USER1, 1_000);
        cmtat.grantRole(ERC20ENFORCER_ROLE, ADMIN);
        vm.stopPrank();
    }

    function testFuzz_TransferRespectsUnfrozenBalance(uint256 freezeAmount, uint256 transferAmount) public {
        freezeAmount = bound(freezeAmount, 0, 1_000);

        vm.prank(ADMIN);
        cmtat.freezePartialTokens(USER1, freezeAmount);

        uint256 active = cmtat.getActiveBalanceOf(USER1);
        transferAmount = bound(transferAmount, 0, 1_200);

        vm.prank(USER1);
        if (transferAmount > active) {
            vm.expectRevert();
            cmtat.transfer(USER2, transferAmount);
        } else {
            bool success = cmtat.transfer(USER2, transferAmount);
            assertTrue(success);
        }
    }
}

contract InvariantHandler {
    Vm internal constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    CMTATStandalone internal token;
    address[4] internal actors;
    address internal admin;

    constructor(CMTATStandalone token_, address admin_, address[4] memory actors_) {
        token = token_;
        admin = admin_;
        actors = actors_;
    }

    function transfer(uint8 fromIdx, uint8 toIdx, uint256 amount) external {
        address from = actors[fromIdx % actors.length];
        address to = actors[toIdx % actors.length];
        if (from == to) return;

        uint256 bal = token.balanceOf(from);
        if (bal == 0) return;
        amount = bound(amount, 0, bal);

        vm.prank(from);
        token.transfer(to, amount);
    }

    function approve(uint8 ownerIdx, uint8 spenderIdx, uint256 amount) external {
        address owner = actors[ownerIdx % actors.length];
        address spender = actors[spenderIdx % actors.length];
        amount = bound(amount, 0, 2_000);

        vm.prank(owner);
        token.approve(spender, amount);
    }

    function transferFrom(uint8 spenderIdx, uint8 fromIdx, uint8 toIdx, uint256 amount) external {
        address spender = actors[spenderIdx % actors.length];
        address from = actors[fromIdx % actors.length];
        address to = actors[toIdx % actors.length];
        if (from == to) return;

        uint256 allowance_ = token.allowance(from, spender);
        uint256 bal = token.balanceOf(from);
        uint256 maxSpend = allowance_ < bal ? allowance_ : bal;
        if (maxSpend == 0) return;
        amount = bound(amount, 0, maxSpend);

        vm.prank(spender);
        token.transferFrom(from, to, amount);
    }

    function mint(uint8 toIdx, uint256 amount) external {
        address to = actors[toIdx % actors.length];
        amount = bound(amount, 0, 100);
        vm.prank(admin);
        token.mint(to, amount);
    }

    function burn(uint8 fromIdx, uint256 amount) external {
        address from = actors[fromIdx % actors.length];
        uint256 bal = token.balanceOf(from);
        if (bal == 0) return;
        amount = bound(amount, 0, bal);

        vm.prank(admin);
        token.burn(from, amount);
    }

    function bound(uint256 x, uint256 min, uint256 max) internal pure returns (uint256) {
        if (max < min) return min;
        if (x < min) return min;
        if (x > max) return max;
        return x;
    }
}

contract CMTATInvariantTest is StdInvariant, HelperContract {
    InvariantHandler internal handler;
    address[4] internal actors;

    function setUp() public {
        _deployToken();

        actors = [ADMIN, USER1, USER2, USER3];

        vm.prank(ADMIN);
        cmtat.mint(ADMIN, 1000);
        vm.prank(ADMIN);
        cmtat.mint(USER1, 1000);
        vm.prank(ADMIN);
        cmtat.mint(USER2, 1000);
        vm.prank(ADMIN);
        cmtat.mint(USER3, 1000);

        handler = new InvariantHandler(cmtat, ADMIN, actors);
        targetContract(address(handler));
    }

    function invariant_TotalSupplyMatchesTrackedActorBalances() public {
        uint256 sum;
        for (uint256 i = 0; i < actors.length; ++i) {
            sum += cmtat.balanceOf(actors[i]);
        }
        assertEq(sum, cmtat.totalSupply());
    }

    function invariant_ActivePlusFrozenEqualsBalanceForTrackedActors() public {
        for (uint256 i = 0; i < actors.length; ++i) {
            address actor = actors[i];
            uint256 balance = cmtat.balanceOf(actor);
            uint256 frozen = cmtat.getFrozenTokens(actor);
            uint256 active = cmtat.getActiveBalanceOf(actor);
            assertEq(active + frozen, balance);
        }
    }
}
