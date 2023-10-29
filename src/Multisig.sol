// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

contract Multisig {

    event TransactionSubmitted(uint256 id, address dest, uint256 value, address sender);
    event TransactionApproved(uint256 id, address owner);
    event TransactionExecuted(uint256 id);

    error FailedToExecute();

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
        require(transactionId < transactions.length, "Transaction not found");
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

        emit TransactionSubmitted(transactionId, destination, value, msg.sender);
        emit TransactionApproved(transactionId, msg.sender);

        return transactionId;
    }

    function approveTxn(uint256 transactionId) external onlyOwner() mustBePending(transactionId) {
        isApproved[transactionId][msg.sender] = true;
        emit TransactionApproved(transactionId, msg.sender);
    }

    function executeTxn(uint256 transactionId) external onlyOwner() mustBePending(transactionId) {
        Transaction storage txn = transactions[transactionId];
        uint numApprovals = 0;
        for (uint i = 0; i < owners.length; i++) {
            if (isApproved[transactionId][owners[i]]) {
                numApprovals += 1;

                if (numApprovals >= numVotesRequired) {
                    transactions[transactionId].isExecuted = true;
                    (bool success, ) = txn.destination.call{value: txn.value, gas: type(uint).max}(txn.data);
                    if (!success) {
                        revert FailedToExecute();
                    } else {
                        emit TransactionExecuted(transactionId);
                        return;
                    }
                }
            }
        }

        revert("Multisig: Not enough approvals");
    }

}
