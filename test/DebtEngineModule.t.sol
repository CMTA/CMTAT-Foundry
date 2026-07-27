//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../script/DeployCMTATStandaloneDebtEngine.s.sol";
import "CMTAT/interfaces/modules/IDebtEngineModule.sol";
import "CMTAT/interfaces/tokenization/ICMTAT.sol";
import "CMTAT/mocks/DebtEngineMock.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

/// @dev Behaviour of the debtEngine variant: debt data is read through an external engine instead of
///      being stored locally, so the read-through, the reset path and the `DEBT_ENGINE_ROLE` gate matter.
contract DebtEngineModuleTest is Test {
    CMTATStandaloneDebtEngine internal cmtat;
    DebtEngineMock internal debtEngine;

    address internal constant ADMIN = address(1);
    address internal constant USER1 = address(2);

    bytes32 internal constant DEBT_ENGINE_ROLE = keccak256("DEBT_ENGINE_ROLE");

    function setUp() public {
        DeployCMTATStandaloneDebtEngine deployer = new DeployCMTATStandaloneDebtEngine();
        cmtat = deployer.deploy(
            ADMIN, "CMTA Token", "CMTAT", 0, "CMTAT_ISIN", "Terms", "https://cmta.ch/terms", "CMTAT_info"
        );
        debtEngine = new DebtEngineMock();
    }

    function _fillEngine() internal {
        ICMTATDebt.DebtInformation memory debt;
        debt.debtIdentifier.issuerName = "CMTA";
        debt.debtInstrument.interestRate = 250;
        debt.debtInstrument.currency = "CHF";
        debtEngine.setDebt(debt);
        debtEngine.setCreditEvents(
            ICMTATCreditEvents.CreditEvents({flagDefault: false, flagRedeemed: true, rating: "AAA"})
        );
    }

    function test_NoDebtEngineByDefaultAndEmptyReads() public {
        assertEq(address(cmtat.debtEngine()), address(0));
        assertEq(cmtat.debt().debtIdentifier.issuerName, "");
        assertEq(cmtat.creditEvents().rating, "");
    }

    function test_AdminCanSetDebtEngineAndReadsGoThroughIt() public {
        _fillEngine();

        vm.prank(ADMIN);
        cmtat.setDebtEngine(debtEngine);

        assertEq(address(cmtat.debtEngine()), address(debtEngine));
        assertEq(cmtat.debt().debtIdentifier.issuerName, "CMTA");
        assertEq(cmtat.debt().debtInstrument.interestRate, 250);
        assertEq(cmtat.debt().debtInstrument.currency, "CHF");
        assertTrue(cmtat.creditEvents().flagRedeemed);
        assertEq(cmtat.creditEvents().rating, "AAA");
    }

    function test_ReadsFollowLaterEngineUpdates() public {
        _fillEngine();
        vm.prank(ADMIN);
        cmtat.setDebtEngine(debtEngine);

        ICMTATDebt.DebtInformation memory updated;
        updated.debtIdentifier.issuerName = "CMTA-2";
        updated.debtInstrument.interestRate = 999;
        debtEngine.setDebt(updated);

        assertEq(cmtat.debt().debtIdentifier.issuerName, "CMTA-2");
        assertEq(cmtat.debt().debtInstrument.interestRate, 999);
    }

    function test_SetDebtEngineEmitsEvent() public {
        vm.expectEmit(true, true, true, true);
        emit IDebtEngineModule.DebtEngine(debtEngine);

        vm.prank(ADMIN);
        cmtat.setDebtEngine(debtEngine);
    }

    function test_ResettingEngineToZeroRestoresEmptyReads() public {
        _fillEngine();
        vm.startPrank(ADMIN);
        cmtat.setDebtEngine(debtEngine);
        cmtat.setDebtEngine(IDebtEngine(address(0)));
        vm.stopPrank();

        assertEq(address(cmtat.debtEngine()), address(0));
        assertEq(cmtat.debt().debtIdentifier.issuerName, "");
        assertEq(cmtat.creditEvents().rating, "");
    }

    function test_RevertWhen_SetDebtEngineSameValue() public {
        vm.startPrank(ADMIN);
        cmtat.setDebtEngine(debtEngine);

        vm.expectRevert(IDebtEngineModule.CMTAT_DebtEngineModule_SameValue.selector);
        cmtat.setDebtEngine(debtEngine);
        vm.stopPrank();
    }

    function test_DebtEngineRoleCanBeGrantedAndUsed() public {
        vm.prank(ADMIN);
        cmtat.grantRole(DEBT_ENGINE_ROLE, USER1);

        vm.prank(USER1);
        cmtat.setDebtEngine(debtEngine);
        assertEq(address(cmtat.debtEngine()), address(debtEngine));
    }

    function test_RevertWhen_NonDebtEngineRoleSetsEngine() public {
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, USER1, DEBT_ENGINE_ROLE)
        );
        cmtat.setDebtEngine(debtEngine);
    }
}
