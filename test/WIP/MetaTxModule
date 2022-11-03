//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/modules/PauseModule.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "./HelperContract.sol";
import "../src/mocks/MinimalForwarderMock.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";


contract MetaTxModuleOwnerTest is Test, HelperContract {
     bool resBool;
     uint256 privateKeyTest = 1000;
     address constant SENDER = vm.addr(privateKeyTest);
     uint256 resUint256;
     MinimalForwarderMock defaultForwarder;
     
    function setUp() public{
        vm.prank(OWNER);
        CMTAT_CONTRACT = new CMTAT();
        defaultForwarder = new MinimalForwarderMock();
        CMTAT_CONTRACT.initialize(OWNER, defaultForwarder, 'CMTA Token', 'CMTAT', 
        'CMTAT_ISIN', 'https://cmta.ch');
    }

    //can change the trustedForwarder
    function testCanChangeTrustedForwarder () {
      MinimalForwarderMock trustedForwarder = new MinimalForwarderMock();
      resBool = CMTAT_CONTRACT.isTrustedForwarder(trustedForwarder);
      assertFalse(resBool);
      resBool = CMTAT_CONTRACT.isTrustedForwarder(defaultForwarder);
      assertEq(resBool, true);
      vm.prank(OWNER);
      CMTAT_CONTRACT.setTrustedForwarder(trustedForwarder);
      resBool = CMTAT_CONTRACT.isTrustedForwarder(trustedForwarder);
      assertEq(resBool, true);
      resBool = CMTAT_CONTRACT.isTrustedForwarder(defaultForwarder);
      assertFalse(resBool);
    }

    // reverts when calling from non-owner
    function testCannnotCallByNonOwner () {
      vm.prank(ADDRESS1);
      string memory message = string(abi.encodePacked('AccessControl: account ', 
      vm.toString(ADDRESS1),' is missing role ', DEFAULT_ADMIN_ROLE_HASH));
      vm.expectRevert(bytes(message));
      CMTAT_CONTRACT.setTrustedForwarder(trustedForwarder);
    }
  }

    // Transferring without paying gas
  contract TransferWithoutPayTest {
    string NAME = 'MinimalForwarder';
    string VERSION = '0.0.1';

    /*
bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
    */
    struct Domain { 
      string NAME;
      string VERSION;
      uint8 chainId;
      address verifyingContract;
    } 


    
    struct Types {

    }
    struct Data { 
      string NAME;
      string VERSION;
      uint8 chainId;
      address verifyingContract;
    } 

    struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes data;
    }

    struct ForwardRequestComponent{
      string name;
      string type;
    }

    ForwardRequestComponent[] EIP712Domain = [
      ForwardRequestComponent({ name: 'name', type: 'string' }),
      ForwardRequestComponent({ name: 'version', type: 'string' }),
      ForwardRequestComponent({ name: 'chainId', type: 'uint256' }),
      ForwardRequestComponent({ name: 'verifyingContract', type: 'address' })
    ];

    function setUp () {
      forwarder = MinimalForwarderMock.new();
      forwarder.initialize();
      vm.prank(OWNER);
      CMTAT_CONTRACT.setTrustedForwarder(address(forwarder));

      Domain domain = new Domain({
        name: NAME,
        version: ,
        chainId: 1,
        verifyingContract: address(forwarder)
      });
      
      ForwardRequestComponent[] memory FW = 
      [
          ForwardRequestComponent({ name: 'from', type: 'address' }),
          ForwardRequestComponent({ name: 'to', type: 'address' }),
          ForwardRequestComponent({ name: 'value', type: 'uint256' }),
          ForwardRequestComponent({ name: 'gas', type: 'uint256' }),
          ForwardRequestComponent({ name: 'nonce', type: 'uint256' }),
          ForwardRequestComponent({ name: 'data', type: 'bytes' })
      ];

      types = {
        EIP712Domain,
        FW,
      };
      Data data = Data ({
        types: types,
        domain: domain,
        primaryType: 'ForwardRequest',
      });
      vm.prank(OWNER);
      CMTAT_CONTRACT.mint(SENDER, 31);
      vm.prank(OWNER);
      CMTAT_CONTRACT.mint(ADDRESS2, 32);
    }

    // can send a transfer transaction without paying gas
    function testCanSendTransactionWithoutPayingGas() {
      const data = CMTAT_CONTRACT.contract.methods.transfer(ADDRESS2, 11).encodeABI();

      ForwardRequest req = ForwardRequest({
        from: sender,
        to: address(CMTAT_CONTRACT),
        value: '0',
        gas: '100000',
        nonce: forwarder.getNonce(SENDER),
        data,
      });

      const sign = vm.sign(privateKeyTest, { data: { ...data, message: req } })
      uint256 balanceBefore = SENDER.balance;
      forwarder.execute(req, sign);
      resUint256 = CMTAT_CONTRACT.balanceOf(SENDER);
      assertEq(resUint256, 20);
      resUint256 = CMTAT_CONTRACT.balanceOf(ADDRESS2);
      assertEq(resUint256, 43);
      uint256 balanceAfter = SENDER.balance;
      assertEq( balanceBefore, balanceAfter);
    }
}
