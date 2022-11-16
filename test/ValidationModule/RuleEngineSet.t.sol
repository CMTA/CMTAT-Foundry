//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "CMTAT/modules/PauseModule.sol";
import "../HelperContract.sol";
import "CMTAT/mocks/RuleEngineMock.sol";

contract RuleEngineSetTest is Test, HelperContract, ValidationModule, RuleMock {
    RuleEngineMock fakeRuleEngine = new RuleEngineMock();
    uint256 resUint256;

    function setUp() public {
        vm.prank(ADMIN_ADDRESS);
        CMTAT_CONTRACT = new CMTAT(ZERO_ADDRESS);
        CMTAT_CONTRACT.initialize(
            ADMIN_ADDRESS,
            "CMTA Token",
            "CMTAT",
            "CMTAT_ISIN",
            "https://cmta.ch"
        );
    }

    function testCanBeSetByAdmin() public {
        // Assert
        vm.expectEmit(true, false, false, false);
        emit RuleEngineSet(address(fakeRuleEngine));

        // Act
        vm.prank(ADMIN_ADDRESS);
        CMTAT_CONTRACT.setRuleEngine(fakeRuleEngine);
    }

    function testCannotBeSetByNonAdmin() public {
        // Assert
        string memory message = string(
            abi.encodePacked(
                "AccessControl: account ",
                vm.toString(ADDRESS1),
                " is missing role ",
                DEFAULT_ADMIN_ROLE_HASH
            )
        );
        vm.expectRevert(bytes(message));
        // Act
        vm.prank(ADDRESS1);
        CMTAT_CONTRACT.setRuleEngine(fakeRuleEngine);
    }
}
