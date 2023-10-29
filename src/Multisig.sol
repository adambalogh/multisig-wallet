// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

contract Multisig {

    struct Transaction {
        uint256 id;
        address destination;
        uint256 value;
        bytes data;
        bool isExecuted;
    }

    address[] public owners;
    mapping(address => bool) private isOwner;

    uint immutable public numVotesRequired;
    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) isApproved;

    constructor(address[] memory _owners, uint _numVotesRequired) payable {
        require(_numVotesRequired >= 1, "At least 1 vote should be required");
        require(_numVotesRequired <= _owners.length, "Num votes cannot be greater than number of owners");

        numVotesRequired = _numVotesRequired;
        owners = _owners;

        for (uint i = 0; i < owners.length; i++) {
            isOwner[owners[i]] = true;
        }
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender] == true, "Must be owner");
        _;
    }

    modifier mustBePending(uint256 transactionId) {
        require(transactionId < transactions.length, "Transaction doesn't exist");
        require(transactions[transactionId].isExecuted == false, "Transaction already executed");
        _;
    }

    function submitTxn(address destination, uint256 value, bytes calldata data) external onlyOwner() returns (uint256) {
        uint256 transactionId = transactions.length;

        transactions.push(Transaction(
            transactionId,
            destination,
            value,
            data,
            false
        ));
        isApproved[transactionId][msg.sender] = true;

        return transactionId;
    }

    function approveTxn(uint256 transactionId) external onlyOwner() mustBePending(transactionId) {
        isApproved[transactionId][msg.sender] = true;
    }

    function executeTxn(uint256 transactionId) external onlyOwner() mustBePending(transactionId) {
        Transaction storage txn = transactions[transactionId];
        uint numApprovals = 0;
        for (uint i = 0; i < owners.length; i++) {
            if (isApproved[transactionId][owners[i]]) {
                numApprovals += 1;

                if (numApprovals >= numVotesRequired) {
                    (bool success, ) = txn.destination.call{value: txn.value, gas: type(uint).max}(txn.data);
                    if (!success) {
                        revert("Multisig: Failed to execute transaction");
                    } else {
                        return;
                    }
                }
            }
        }

        revert("Multisig: Not enough approvals");
    }

}
