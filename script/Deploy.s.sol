// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/Multisig.sol";

contract Deploy is Script {

    address[] private owners;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        address deployerAddress = vm.envAddress("ADDRESS");
        address secondAddress = vm.envAddress("ADDRESS_2");

        owners = [deployerAddress, secondAddress];

        vm.startBroadcast(deployerPrivateKey);

        new Multisig(owners, 2);

        vm.stopBroadcast();
    }
}
