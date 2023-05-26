//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.17;
import "./HelperContract.sol";

contract BurnModuleTest is Test, HelperContract, BurnModule {
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
        vm.prank(DEFAULT_ADMIN_ADDRESS);
        CMTAT_CONTRACT.mint(ADDRESS1, 50);
        resUint256 = CMTAT_CONTRACT.totalSupply();
        assertEq(resUint256, 50);
    }

    /**
    The admin is assigned the BURNER role when the contract is deployed
    */
    function testCanBeBurntByAdminWithAllowance() public {
        // Arrange
        vm.prank(ADDRESS1);
        CMTAT_CONTRACT.approve(DEFAULT_ADMIN_ADDRESS, 50);

        // Burn 20
        // Assert
        vm.expectEmit(true, true, false, true);
        emit Transfer(ADDRESS1, ZERO_ADDRESS, 20);
        // TODO: add reason argument
        //vm.expectEmit(true, false, false, true);
        //emit Burn(ADDRESS1, 20);

        // Act
        vm.prank(DEFAULT_ADMIN_ADDRESS);
        CMTAT_CONTRACT.forceBurn(ADDRESS1, 20, "");
        
        // Assert
        // Check balances and total supply
        resUint256 = CMTAT_CONTRACT.balanceOf(ADDRESS1);
        assertEq(resUint256, 30);
        resUint256 = CMTAT_CONTRACT.totalSupply();
        assertEq(resUint256, 30);

        // Burn 30
        // Assert
        vm.expectEmit(true, true, false, true);
        emit Transfer(ADDRESS1, ZERO_ADDRESS, 30);
        /*
        // TODO: add reason argument
        vm.expectEmit(true, false, false, true);
        emit Burn(ADDRESS1, 30);
        
        */

        // Act
        vm.prank(DEFAULT_ADMIN_ADDRESS);
        CMTAT_CONTRACT.forceBurn(ADDRESS1, 30, "");

        // Assert
        // check balances and total supply
        resUint256 = CMTAT_CONTRACT.balanceOf(ADDRESS1);
        assertEq(resUint256, 0);
        resUint256 = CMTAT_CONTRACT.totalSupply();
        assertEq(resUint256, 0);
    }

    function testCanBeBurntByBurnerRole() public {
        // Arrange
        vm.prank(DEFAULT_ADMIN_ADDRESS);
        CMTAT_CONTRACT.grantRole(BURNER_ROLE, ADDRESS2);
        vm.prank(ADDRESS1);
        CMTAT_CONTRACT.approve(ADDRESS2, 50);

        // Assert
        vm.expectEmit(true, true, false, true);
        emit Transfer(ADDRESS1, ZERO_ADDRESS, 20);
        /*
        // TODO: add reason argument
        vm.expectEmit(true, false, false, true);
        emit Burn(ADDRESS1, 20);
        */
        // Act
        vm.prank(ADDRESS2);
        CMTAT_CONTRACT.forceBurn(ADDRESS1, 20, "");

        // Assert
        resUint256 = CMTAT_CONTRACT.balanceOf(ADDRESS1);
        assertEq(resUint256, 30);
        resUint256 = CMTAT_CONTRACT.totalSupply();
        assertEq(resUint256, 30);
    }

    function testCannotBeBurntIfBalanceExceeds() public {
        // Assert
        vm.expectRevert(bytes("ERC20: burn amount exceeds balance"));
        // Act
        vm.prank(DEFAULT_ADMIN_ADDRESS);
        CMTAT_CONTRACT.forceBurn(ADDRESS1, 200, "");
    }

    function testCannotBeBurntWithoutBurnerRole() public {
        // Assert
        string memory message = string(
            abi.encodePacked(
                "AccessControl: account ",
                vm.toString(ADDRESS2),
                " is missing role ",
                BURNER_ROLE_HASH
            )
        );
        vm.expectRevert(bytes(message));
        // Act
        vm.prank(ADDRESS2);
        CMTAT_CONTRACT.forceBurn(ADDRESS1, 20, "");
    }
}
