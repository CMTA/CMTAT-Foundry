//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "./HelperContract.sol";

contract BaseModuleTest is Test, HelperContract, BaseModule {
    function setUp() public {
        vm.prank(OWNER);
        CMTAT_CONTRACT = new CMTAT(ZERO_ADDRESS, false,
            OWNER,
            "CMTA Token",
            "CMTAT",
            "CMTAT_ISIN",
            "https://cmta.ch");
    }

    function testHasTheDefinedName() public {
        // Act
        string memory res1 = CMTAT_CONTRACT.name();
        // Assert
        assertEq(res1, "CMTA Token");
    }

    function testHasDefinedSymbol() public {
        // Act
        string memory res1 = CMTAT_CONTRACT.symbol();
        // Assert
        assertEq(res1, "CMTAT");
    }

    function testDecimalsEqual0() public {
        // Act
        uint8 res1 = CMTAT_CONTRACT.decimals();
        // Assert
        assertEq(res1, 0);
    }

    function testHasTheDefinedTokenId() public {
        // Act
        string memory res1 = CMTAT_CONTRACT.tokenId();
        // Assert
        assertEq(res1, "CMTAT_ISIN");
    }

    function testHasTheDefinedTerms() public {
        // Act
        string memory res1 = CMTAT_CONTRACT.terms();
        // Assert
        assertEq(res1, "https://cmta.ch");
    }

    function testAdminCanChangeTokenId() public {
        // Arrange
        string memory res1 = CMTAT_CONTRACT.tokenId();
        // Arrange - Assert
        assertEq(res1, "CMTAT_ISIN");
        // Act
        vm.prank(OWNER);
        CMTAT_CONTRACT.setTokenId("CMTAT_TOKENID");
        // Assert
        string memory res2 = CMTAT_CONTRACT.tokenId();
        assertEq(res2, "CMTAT_TOKENID");
    }

    function testCannotNonAdminChangeTokenId() public {
        // Arrange - Assert
        string memory res1 = CMTAT_CONTRACT.tokenId();
        assertEq(res1, "CMTAT_ISIN");
        // Act
        vm.prank(ADDRESS1);
        string memory message = string(
            abi.encodePacked(
                "AccessControl: account ",
                vm.toString(ADDRESS1),
                " is missing role ",
                DEFAULT_ADMIN_ROLE_HASH
            )
        );
        vm.expectRevert(bytes(message));
        CMTAT_CONTRACT.setTokenId("CMTAT_TOKENID");
        // Assert
        string memory res2 = CMTAT_CONTRACT.tokenId();
        assertEq(res2, "CMTAT_ISIN");
    }

    function testAdminCanUpdateTerms() public {
        // Arrange - Assert
        string memory res1 = CMTAT_CONTRACT.terms();
        assertEq(res1, "https://cmta.ch");
        // Act
        vm.prank(OWNER);
        CMTAT_CONTRACT.setTerms("https://cmta.ch/terms");
        // Assert
        string memory res2 = CMTAT_CONTRACT.terms();
        assertEq(res2, "https://cmta.ch/terms");
    }

    function testCannotNonAdminUpdateTerms() public {
        // Arrange - Assert
        string memory res1 = CMTAT_CONTRACT.terms();
        assertEq(res1, "https://cmta.ch");
        // act
        vm.prank(ADDRESS1);
        string memory message = string(
            abi.encodePacked(
                "AccessControl: account ",
                vm.toString(ADDRESS1),
                " is missing role ",
                DEFAULT_ADMIN_ROLE_HASH
            )
        );
        vm.expectRevert(bytes(message));
        CMTAT_CONTRACT.setTerms("https://cmta.ch/terms");
        // Assert
        string memory res2 = CMTAT_CONTRACT.terms();
        assertEq(res2, "https://cmta.ch");
    }

    function testAdminCanKillContract() public {
        vm.prank(OWNER);
        CMTAT_CONTRACT.kill();
        // TODO : Check if the contract is really kill
        //  Check if the ethers inside the contract is sent to the right address
    }

    function testCannotNonAdminKillContract() public {
        // Act
        string memory message = string(
            abi.encodePacked(
                "AccessControl: account ",
                vm.toString(ADDRESS1),
                " is missing role ",
                DEFAULT_ADMIN_ROLE_HASH
            )
        );
        vm.expectRevert(bytes(message));
        vm.prank(ADDRESS1);
        CMTAT_CONTRACT.kill();
        // Assert
        string memory res1 = CMTAT_CONTRACT.terms();
        assertEq(res1, "https://cmta.ch");
    }
}

contract AllowanceTest is Test, HelperContract, BaseModule, ERC20BaseModule {
    function setUp() public {
        vm.prank(OWNER);
        CMTAT_CONTRACT = new CMTAT(ZERO_ADDRESS, false,
            OWNER,
            "CMTA Token",
            "CMTAT",
            "CMTAT_ISIN",
            "https://cmta.ch");
    }

    // address1 -> address3
    function testApproveAllowance() public {
        // Arrange - Assert
        uint256 res1 = CMTAT_CONTRACT.allowance(ADDRESS1, ADDRESS3);
        assertEq(res1, 0);

        // Act
        vm.prank(ADDRESS1);
        vm.expectEmit(true, true, false, true);
        // emits an Approval event
        emit Approval(ADDRESS1, ADDRESS3, 20);
        CMTAT_CONTRACT.approve(ADDRESS3, 20);
        // Assert
        uint256 res2 = CMTAT_CONTRACT.allowance(ADDRESS1, ADDRESS3);
        assertEq(res2, 20);
    }

    // ADDRESS1 -> ADDRESS3
    function testIncreaseAllowance() public {
        // Arrange
        uint256 res1 = CMTAT_CONTRACT.allowance(ADDRESS1, ADDRESS3);
        assertEq(res1, 0);
        vm.prank(ADDRESS1);
        CMTAT_CONTRACT.approve(ADDRESS3, 20);
        // Arrange - Assert
        uint256 res2 = CMTAT_CONTRACT.allowance(ADDRESS1, ADDRESS3);
        assertEq(res2, 20);
        // Act
        vm.expectEmit(true, true, false, true);
        emit Approval(ADDRESS1, ADDRESS3, 30);
        vm.prank(ADDRESS1);
        CMTAT_CONTRACT.increaseAllowance(ADDRESS3, 10);
        // Assert
        uint256 res3 = CMTAT_CONTRACT.allowance(ADDRESS1, ADDRESS3);
        assertEq(res3, 30);
    }

    // ADDRESS1 -> ADDRESS3
    function testDecreaseAllowance() public {
        // Arrange
        uint256 res1 = CMTAT_CONTRACT.allowance(ADDRESS1, ADDRESS3);
        assertEq(res1, 0);
        vm.prank(ADDRESS1);
        CMTAT_CONTRACT.approve(ADDRESS3, 20);
        // Arrange - Assert
        uint256 res2 = CMTAT_CONTRACT.allowance(ADDRESS1, ADDRESS3);
        assertEq(res2, 20);
        // Act
        vm.prank(ADDRESS1);
        vm.expectEmit(true, true, false, true);
        emit Approval(ADDRESS1, ADDRESS3, 10);
        CMTAT_CONTRACT.decreaseAllowance(ADDRESS3, 10);
        // Assert
        uint256 res3 = CMTAT_CONTRACT.allowance(ADDRESS1, ADDRESS3);
        assertEq(res3, 10);
    }

    // ADDRESS1 -> ADDRESS3
    function testRedefinedAllowanceWithApprove() public {
        // Arrange
        uint256 res1 = CMTAT_CONTRACT.allowance(ADDRESS1, ADDRESS3);
        assertEq(res1, 0);
        vm.prank(ADDRESS1);
        CMTAT_CONTRACT.approve(ADDRESS3, 20);
        // Arrange - Assert
        uint256 res2 = CMTAT_CONTRACT.allowance(ADDRESS1, ADDRESS3);
        assertEq(res2, 20);
        // Act
        vm.prank(ADDRESS1);
        vm.expectEmit(true, true, false, true);
        // emits an Approval event
        emit Approval(ADDRESS1, ADDRESS3, 50);
        CMTAT_CONTRACT.approve(ADDRESS3, 50);
        // Assert
        uint256 res3 = CMTAT_CONTRACT.allowance(ADDRESS1, ADDRESS3);
        assertEq(res3, 50);
    }

    // ADDRESS1 -> ADDRESS3
    function testDefinedAllowanceByTakingInAccountTheCurrentAllowance() public {
        // Arrange
        uint256 res1 = CMTAT_CONTRACT.allowance(ADDRESS1, ADDRESS3);
        assertEq(res1, 0);
        vm.prank(ADDRESS1);
        CMTAT_CONTRACT.approve(ADDRESS3, 20);
        // Arrange - Assert
        uint256 res2 = CMTAT_CONTRACT.allowance(ADDRESS1, ADDRESS3);
        assertEq(res2, 20);
        // Act
        vm.prank(ADDRESS1);
        vm.expectEmit(true, true, false, true);
        emit Approval(ADDRESS1, ADDRESS3, 30);
        CMTAT_CONTRACT.approve(ADDRESS3, 30, 20);
        // Assert
        uint256 res3 = CMTAT_CONTRACT.allowance(ADDRESS1, ADDRESS3);
        assertEq(res3, 30);
    }

    // ADDRESS1 -> ADDRESS3
    function testCannotDefinedAllowanceByTakingInAccountTheWrongCurrentAllowance() public {
        // Arrange
        uint256 res1 = CMTAT_CONTRACT.allowance(ADDRESS1, ADDRESS3);
        assertEq(res1, 0);
        vm.prank(ADDRESS1);
        CMTAT_CONTRACT.approve(ADDRESS3, 20);
        // Arrange - Assert
        uint256 res2 = CMTAT_CONTRACT.allowance(ADDRESS1, ADDRESS3);
        assertEq(res2, 20);
        // Act
        vm.prank(ADDRESS1);
        vm.expectRevert(bytes("CMTAT: current allowance is not right"));
        CMTAT_CONTRACT.approve(ADDRESS3, 30, 10);
        // Assert
        uint256 res3 = CMTAT_CONTRACT.allowance(ADDRESS1, ADDRESS3);
        assertEq(res3, 20);
    }
}

contract TransferTest is Test, HelperContract, BaseModule, ERC20BaseModule {
    function setUp() public {
        vm.prank(OWNER);
        CMTAT_CONTRACT = new CMTAT(ZERO_ADDRESS, false,
            OWNER,
            "CMTA Token",
            "CMTAT",
            "CMTAT_ISIN",
            "https://cmta.ch");

        // Personal config
        vm.prank(OWNER);
        CMTAT_CONTRACT.mint(ADDRESS1, 31);

        vm.prank(OWNER);
        CMTAT_CONTRACT.mint(ADDRESS2, 32);

        vm.prank(OWNER);
        CMTAT_CONTRACT.mint(ADDRESS3, 33);
    }

    // ADDRESS1 -> ADDRESS2
    function testTransferFromOneAccountToAnother() public {
        // Act
        vm.prank(ADDRESS1);
        vm.expectEmit(true, true, false, true);
        // emits a Transfer event
        emit Transfer(ADDRESS1, ADDRESS2, 11);

        CMTAT_CONTRACT.transfer(ADDRESS2, 11);
        // Assert
        uint256 res1 = CMTAT_CONTRACT.balanceOf(ADDRESS1);
        assertEq(res1, 20);

        uint256 res2 = CMTAT_CONTRACT.balanceOf(ADDRESS2);
        assertEq(res2, 43);

        uint256 res3 = CMTAT_CONTRACT.balanceOf(ADDRESS3);
        assertEq(res3, 33);

        uint256 res4 = CMTAT_CONTRACT.totalSupply();
        assertEq(res4, 96);
    }

    // ADDRESS1 -> ADDRESS2
    function testCannotTransferMoreTokensThanOwn() public {
        // Act
        vm.expectRevert(bytes("ERC20: transfer amount exceeds balance"));
        vm.prank(ADDRESS1);
        CMTAT_CONTRACT.transfer(ADDRESS2, 50);
    }

    // allows ADDRESS3 to transfer tokens from ADDRESS1 to ADDRESS2
    // ADDRESS3 : ADDRESS1 -> ADDRESS2
    function testTransferByAnotherAccountWithTheRightAllowance() public {
        // Arrange
        vm.prank(ADDRESS1);
        CMTAT_CONTRACT.approve(ADDRESS3, 20);
        
        // Act
        // Transfer
        vm.prank(ADDRESS3);
        // emits a Transfer event
        vm.expectEmit(true, true, false, true);
        emit Transfer(ADDRESS1, ADDRESS2, 11);
        vm.expectEmit(true, true, false, true);
        // emits a Spend event
        emit Spend(ADDRESS1, ADDRESS3, 11);
        CMTAT_CONTRACT.transferFrom(ADDRESS1, ADDRESS2, 11);
        
        // Assert
        uint256 res1 = CMTAT_CONTRACT.balanceOf(ADDRESS1);
        assertEq(res1, 20);
        uint256 res2 = CMTAT_CONTRACT.balanceOf(ADDRESS2);
        assertEq(res2, 43);
        uint256 res3 = CMTAT_CONTRACT.balanceOf(ADDRESS3);
        assertEq(res3, 33);
        uint256 res4 = CMTAT_CONTRACT.totalSupply();
        assertEq(res4, 96);
    }

    // reverts if ADDRESS3 transfers more tokens than the
    // allowance from ADDRESS1 to ADDRESS2
    function testCannotTransferByAnotherAccountWithInsufficientAllowance() public {
        // Arrange
        // Define allowance
        uint256 res1 = CMTAT_CONTRACT.allowance(ADDRESS1, ADDRESS3);
        assertEq(res1, 0);
        vm.prank(ADDRESS1);
        CMTAT_CONTRACT.approve(ADDRESS3, 20);
        // Arrange - Assert
        uint256 res2 = CMTAT_CONTRACT.allowance(ADDRESS1, ADDRESS3);
        assertEq(res2, 20);
        // Act
        // Transfer
        vm.expectRevert(bytes("ERC20: insufficient allowance"));
        vm.prank(ADDRESS3);
        CMTAT_CONTRACT.transferFrom(ADDRESS1, ADDRESS2, 31);
    }

    // reverts if ADDRESS3 transfers more tokens
    // than ADDRESS1 owns from ADDRESS1 to ADDRESS2
    function testCannotTransferByAnotherAccountWithInsufficientBalance() public {
        // Arrange
        vm.prank(ADDRESS1);
        CMTAT_CONTRACT.approve(ADDRESS3, 1000);
        // Act
        vm.expectRevert(bytes("ERC20: transfer amount exceeds balance"));
        vm.prank(ADDRESS3);
        CMTAT_CONTRACT.transferFrom(ADDRESS1, ADDRESS2, 50);
    }
}
