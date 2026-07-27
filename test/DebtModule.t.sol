//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../script/DeployCMTATStandaloneDebt.s.sol";
import "CMTAT/interfaces/modules/IDebtModule.sol";
import "CMTAT/interfaces/tokenization/ICMTAT.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

/// @dev Behaviour of the debt variant: the `DebtModule` storage, its `DEBT_ROLE` gate and its log events.
contract DebtModuleTest is Test {
    CMTATStandaloneDebt internal cmtat;

    address internal constant ADMIN = address(1);
    address internal constant USER1 = address(2);

    bytes32 internal constant DEBT_ROLE = keccak256("DEBT_ROLE");

    function setUp() public {
        DeployCMTATStandaloneDebt deployer = new DeployCMTATStandaloneDebt();
        cmtat = deployer.deploy(
            ADMIN, "CMTA Token", "CMTAT", 0, "CMTAT_ISIN", "Terms", "https://cmta.ch/terms", "CMTAT_info"
        );
    }

    function _debtInformation() internal pure returns (ICMTATDebt.DebtInformation memory) {
        return ICMTATDebt.DebtInformation({
            debtIdentifier: ICMTATDebt.DebtIdentifier({
                issuerName: "CMTA",
                issuerDescription: "Issuer description",
                guarantor: "Guarantor",
                debtHolder: "Holder"
            }),
            debtInstrument: _debtInstrument()
        });
    }

    function _debtInstrument() internal pure returns (ICMTATDebt.DebtInstrument memory) {
        return ICMTATDebt.DebtInstrument({
            interestRate: 500,
            parValue: 1_000,
            minimumDenomination: 10,
            issuanceDate: "2026-01-01",
            maturityDate: "2031-01-01",
            couponPaymentFrequency: "annual",
            interestScheduleFormat: "A",
            interestPaymentDate: "2026-12-31",
            dayCountConvention: "30/360",
            businessDayConvention: "following",
            currency: "CHF",
            currencyContract: address(0)
        });
    }

    function test_DebtIsEmptyByDefault() public {
        ICMTATDebt.DebtInformation memory debt = cmtat.debt();
        assertEq(debt.debtIdentifier.issuerName, "");
        assertEq(debt.debtInstrument.interestRate, 0);
        assertEq(debt.debtInstrument.parValue, 0);
    }

    function test_AdminCanSetDebtAndReadItBack() public {
        vm.prank(ADMIN);
        cmtat.setDebt(_debtInformation());

        ICMTATDebt.DebtInformation memory debt = cmtat.debt();
        assertEq(debt.debtIdentifier.issuerName, "CMTA");
        assertEq(debt.debtIdentifier.debtHolder, "Holder");
        assertEq(debt.debtInstrument.interestRate, 500);
        assertEq(debt.debtInstrument.maturityDate, "2031-01-01");
        assertEq(debt.debtInstrument.currency, "CHF");
    }

    function test_SetDebtEmitsLogEvent() public {
        vm.expectEmit(true, true, true, true);
        emit IDebtModule.DebtLogEvent();

        vm.prank(ADMIN);
        cmtat.setDebt(_debtInformation());
    }

    function test_SetDebtInstrumentOnlyReplacesTheInstrument() public {
        vm.startPrank(ADMIN);
        cmtat.setDebt(_debtInformation());

        ICMTATDebt.DebtInstrument memory updated = _debtInstrument();
        updated.interestRate = 750;
        updated.currency = "EUR";

        vm.expectEmit(true, true, true, true);
        emit IDebtModule.DebtInstrumentLogEvent();
        cmtat.setDebtInstrument(updated);
        vm.stopPrank();

        ICMTATDebt.DebtInformation memory debt = cmtat.debt();
        assertEq(debt.debtInstrument.interestRate, 750);
        assertEq(debt.debtInstrument.currency, "EUR");
        // the identifier part is untouched
        assertEq(debt.debtIdentifier.issuerName, "CMTA");
    }

    function test_AdminCanSetCreditEvents() public {
        vm.expectEmit(true, true, true, true);
        emit IDebtModule.CreditEventsLogEvent();

        vm.prank(ADMIN);
        cmtat.setCreditEvents(ICMTATCreditEvents.CreditEvents({flagDefault: true, flagRedeemed: false, rating: "AA"}));

        ICMTATCreditEvents.CreditEvents memory creditEvents = cmtat.creditEvents();
        assertTrue(creditEvents.flagDefault);
        assertFalse(creditEvents.flagRedeemed);
        assertEq(creditEvents.rating, "AA");
    }

    function test_DebtRoleCanBeGrantedAndUsed() public {
        vm.prank(ADMIN);
        cmtat.grantRole(DEBT_ROLE, USER1);

        vm.prank(USER1);
        cmtat.setDebt(_debtInformation());
        assertEq(cmtat.debt().debtIdentifier.issuerName, "CMTA");
    }

    function test_RevertWhen_NonDebtRoleSetsDebtData() public {
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, USER1, DEBT_ROLE)
        );
        cmtat.setDebt(_debtInformation());

        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, USER1, DEBT_ROLE)
        );
        cmtat.setDebtInstrument(_debtInstrument());

        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, USER1, DEBT_ROLE)
        );
        cmtat.setCreditEvents(ICMTATCreditEvents.CreditEvents({flagDefault: true, flagRedeemed: true, rating: "B"}));
    }

    function test_RevokedDebtRoleCannotSetDebt() public {
        vm.startPrank(ADMIN);
        cmtat.grantRole(DEBT_ROLE, USER1);
        cmtat.revokeRole(DEBT_ROLE, USER1);
        vm.stopPrank();

        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, USER1, DEBT_ROLE)
        );
        cmtat.setDebt(_debtInformation());
    }
}
