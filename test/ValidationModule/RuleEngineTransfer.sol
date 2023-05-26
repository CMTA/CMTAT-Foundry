//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../HelperContract.sol";
import "CMTAT/mocks/RuleEngine/RuleEngineMock.sol";
import "./CodeListInternal.sol";
// Transferring with Rule Engine set
contract RuleEngineTransferTest is Test, HelperContract, ValidationModule, CodeListInternal{
    RuleEngineMock ruleEngineMock;
    uint256 resUint256;
    uint8 resUint8;
    string resString;

    function setUp() public {
        vm.prank(DEFAULT_ADMIN_ADDRESS);
        CMTAT_CONTRACT = new CMTAT_STANDALONE(
            ZERO_ADDRESS,
            DEFAULT_ADMIN_ADDRESS,
            "CMTA Token",
            "CMTAT",
            "CMTAT_ISIN",
            "https://cmta.ch",
            IRuleEngine(address(0)),
            "CMTAT_info",
            FLAG
        );

        // Specific configuration for the tests
        vm.prank(DEFAULT_ADMIN_ADDRESS);
        ruleEngineMock = new RuleEngineMock();
        vm.prank(DEFAULT_ADMIN_ADDRESS);
        CMTAT_CONTRACT.mint(ADDRESS1, 31);
        vm.prank(DEFAULT_ADMIN_ADDRESS);
        CMTAT_CONTRACT.mint(ADDRESS2, 32);
        vm.prank(DEFAULT_ADMIN_ADDRESS);
        CMTAT_CONTRACT.mint(ADDRESS3, 33);
        vm.prank(DEFAULT_ADMIN_ADDRESS);
        CMTAT_CONTRACT.setRuleEngine(ruleEngineMock);
    }

    function testCanDetectTransferRestrictionValidTransfer() public {
        // Act
        resUint8 = CMTAT_CONTRACT.detectTransferRestriction(
            ADDRESS1,
            ADDRESS2,
            11
        );
        // Assert
        assertEq(resUint8, 0);
    }

    function testCanReturnMessageValidTransfer() public {
        // Act
        resString = CMTAT_CONTRACT.messageForTransferRestriction(
            0
        );
        // Assert
        assertEq(resString, "No restriction");
    }

    function testCanDetectTransferRestrictionWithAmountTooHigh() public {
        // Act
       resUint8 = CMTAT_CONTRACT.detectTransferRestriction(
            ADDRESS1,
            ADDRESS2,
            21
        );
        // Assert
        assertEq(resUint8, AMOUNT_TOO_HIGH);
    }

    function testCanReturnMessageWithAmountTooHigh() public {
        // Act
        resString = CMTAT_CONTRACT.messageForTransferRestriction(
            AMOUNT_TOO_HIGH
        );
        // Assert
        assertEq(resString, TEXT_AMOUNT_TOO_HIGH);
    }

    // allows ADDRESS1 to transfer tokens to ADDRESS2
    function testCanTransferAllowedByRule() public {
        // Act
        vm.prank(ADDRESS1);
        CMTAT_CONTRACT.transfer(ADDRESS2, 11);
        // Assert
        resUint256 = CMTAT_CONTRACT.balanceOf(ADDRESS1);
        assertEq(resUint256, 20);
        resUint256 = CMTAT_CONTRACT.balanceOf(ADDRESS2);
        assertEq(resUint256, 43);
        resUint256 = CMTAT_CONTRACT.balanceOf(ADDRESS3);
        assertEq(resUint256, 33);
    }

    // reverts if ADDRESS1 transfers more tokens than rule allows
    function testCannotTransferIfNotAllowedByRule() public {
        vm.prank(ADDRESS1);
        vm.expectRevert(bytes("CMTAT: transfer rejected by validation module"));
        CMTAT_CONTRACT.transfer(ADDRESS2, 21);
    }
}
