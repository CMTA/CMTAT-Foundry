//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../HelperContract.sol";
import "CMTAT/mocks/RuleEngine/RuleEngineMock.sol";
import "./CodeListInternal.sol";
contract RuleEngineSetTest is Test, HelperContract, ValidationModule, CodeListInternal {
    RuleEngineMock fakeRuleEngine = new RuleEngineMock();
    uint256 resUint256;

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
    }

    function testCanBeSetByAdmin() public {
        // Assert
        vm.expectEmit(true, false, false, false);
        emit RuleEngine(IRuleEngine(fakeRuleEngine));

        // Act
        vm.prank(DEFAULT_ADMIN_ADDRESS);
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
