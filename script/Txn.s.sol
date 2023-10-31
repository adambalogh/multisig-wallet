// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/Multisig.sol";

contract Transfer is Script {

    Multisig wallet = Multisig(0x145F32E62c7f1d89A5a08aB67c7585A9c85B12c7);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        uint256 secondAddressPrivateKey = vm.envUint("PRIVATE_KEY_2");

        address secondAddress = vm.envAddress("ADDRESS_2");

        vm.startBroadcast(deployerPrivateKey);
        uint256 txnId = wallet.submitTxn(secondAddress, 0.001 ether, "");
        vm.stopBroadcast();

        vm.startBroadcast(secondAddressPrivateKey);
        wallet.approveTxn(txnId);
        wallet.executeTxn(txnId);
        vm.stopBroadcast();
    }

}