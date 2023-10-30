// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/Multisig.sol";

contract Deploy is Script {

    address[] owners;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        Multisig wallet = new Wallet(owners, 2);

        vm.stopBroadcast();
    }
}
