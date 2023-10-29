// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "src/Multisig.sol";

contract Counter {
    uint256 public count;

    constructor() {
        count = 0;
    }

    function increment() external {
        count += 1;
    }
}

contract TestMultisig is Test {
    Multisig wallet;
    Counter counter;

    address internal alice;
    address internal bob;
    address internal charlie;

    address[] internal owners;

    function setUp() public {
        alice = address(1);
        bob = address(2);
        charlie = address(3);

        owners = [alice, bob];

        wallet = new Multisig(owners, 2);
        vm.deal(address(wallet), 1 ether);

        assertEq(wallet.owners(0), alice);
        assertEq(wallet.owners(1), bob);
        assertEq(address(wallet).balance, 1 ether);

        counter = new Counter();
        assertEq(address(counter).balance, 0 ether);
    }

    function testPermissions() public {
        vm.prank(alice);
        uint256 transactionId = wallet.submitTxn(bob, 0.1 ether, "");

        vm.expectRevert();
        vm.prank(charlie);
        wallet.approveTxn(transactionId);

        vm.prank(bob);
        wallet.approveTxn(transactionId);
    }

    function testCannotApproveMultipleTimes() public {
        vm.prank(alice);
        uint256 transactionId = wallet.submitTxn(bob, 0.1 ether, "");

        vm.prank(alice);
        wallet.approveTxn(transactionId);

        vm.expectRevert();
        vm.prank(alice);
        wallet.executeTxn(transactionId);
    }

    function testTransfer() public {
        vm.prank(alice);
        uint256 transactionId = wallet.submitTxn(bob, 0.1 ether, "");
        assertEq(alice.balance, 0 ether);

        // not enough approvals yet
        vm.expectRevert();
        vm.prank(alice);
        wallet.executeTxn(transactionId);
        
        vm.prank(bob);
        wallet.approveTxn(transactionId);

        vm.prank(alice);
        wallet.executeTxn(transactionId);
        assertEq(bob.balance, 0.1 ether);
        assertEq(address(wallet).balance, 0.9 ether);
    }

    function testCannotExecuteTwice() public {
        vm.prank(alice);
        uint256 transactionId = wallet.submitTxn(bob, 0.1 ether, "");
        assertEq(alice.balance, 0 ether);

        vm.prank(bob);
        wallet.approveTxn(transactionId);

        vm.prank(alice);
        wallet.executeTxn(transactionId);

        vm.expectRevert();
        vm.prank(alice);
        wallet.executeTxn(transactionId);

        assertEq(bob.balance, 0.1 ether);
        assertEq(address(wallet).balance, 0.9 ether);
    }

    function testFunctionCall() public {
        assertEq(counter.count(), 0);

        vm.prank(alice);
        uint256 transactionId = wallet.submitTxn(address(counter), 0, abi.encodeWithSignature("increment()"));
        assertEq(counter.count(), 0);

        vm.prank(bob);
        wallet.approveTxn(transactionId);

        vm.prank(alice);
        wallet.executeTxn(transactionId);
        assertEq(address(wallet).balance, 1 ether);
        assertEq(counter.count(), 1);
    }
}
