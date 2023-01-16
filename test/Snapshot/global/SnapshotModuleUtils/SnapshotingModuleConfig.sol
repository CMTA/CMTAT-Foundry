///SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.17;
import "../../../HelperContract.sol";
contract SnapshotingModuleConfig is Test, HelperContract, SnapshotModule {
    function config() public {
        vm.warp(200);
        vm.prank(OWNER);
        CMTAT_CONTRACT = new CMTAT(ZERO_ADDRESS, false,
            OWNER,
            "CMTA Token",
            "CMTAT",
            "CMTAT_ISIN",
            "https://cmta.ch");

        // Config personal
        vm.prank(OWNER);
        CMTAT_CONTRACT.mint(ADDRESS1, 31);
        vm.prank(OWNER);
        CMTAT_CONTRACT.mint(ADDRESS2, 32);
        vm.prank(OWNER);
        CMTAT_CONTRACT.mint(ADDRESS3, 33);
    }
}