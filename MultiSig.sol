// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TriSigWallet {
    // Define the owners of the wallet
    address public owner1;
    address public owner2;
    address public owner3;

    // Counter for transaction IDs
    uint256 public transactionCount;

    // Mapping to track whether an owner has approved a transaction
    mapping(uint256 => mapping(address => bool)) public approvals;

    // Event emitted when a new transaction is proposed
    event TransactionProposed(uint256 indexed transactionId, address indexed destination, uint256 amount);

    // Event emitted when a transaction is approved and executed
    event TransactionExecuted(uint256 indexed transactionId, address indexed destination, uint256 amount);

    // Modifier to check if the caller is one of the owners
    modifier onlyOwners() {
        require(
            msg.sender == owner1 || msg.sender == owner2 || msg.sender == owner3,
            "Not an owner"
        );
        _;
    }

    // Modifier to check if a transaction has not been executed yet
    modifier notExecuted(uint256 transactionId) {
        require(!isExecuted(transactionId), "Transaction already executed");
        _;
    }

    // Constructor to set the initial owners
    constructor(address _owner1, address _owner2, address _owner3) {
        owner1 = _owner1;
        owner2 = _owner2;
        owner3 = _owner3;
    }

    // Function to propose a new transaction
    function proposeTransaction(address destination, uint256 amount)
        external
        onlyOwners
        returns (uint256)
    {
        // Increment the transaction counter
        transactionCount++;

        // Emit an event for the proposed transaction
        emit TransactionProposed(transactionCount, destination, amount);

        // Return the transaction ID
        return transactionCount;
    }

    // Function for owners to approve a transaction
    function approveTransaction(uint256 transactionId)
        external
        onlyOwners
        notExecuted(transactionId)
    {
        // Mark the approval from the calling owner for the specified transaction
        approvals[transactionId][msg.sender] = true;

        // Check if the transaction has received approvals from at least two owners
        if (isApproved(transactionId)) {
            // Execute the transaction
            executeTransaction(transactionId);
        }
    }

    // Function to check if a transaction has received approvals from at least two owners
    function isApproved(uint256 transactionId) internal view returns (bool) {
        uint256 approvalCount = 0;

        if (approvals[transactionId][owner1]) {
            approvalCount++;
        }

        if (approvals[transactionId][owner2]) {
            approvalCount++;
        }

        if (approvals[transactionId][owner3]) {
            approvalCount++;
        }

        return approvalCount >= 2;
    }

    // Function to check if a transaction has been executed
    function isExecuted(uint256 transactionId) internal view returns (bool) {
        return approvals[transactionId][owner1] && approvals[transactionId][owner2];
    }

    // Function to execute a transaction
    function executeTransaction(uint256 transactionId) internal {
        // Get the destination and amount of the transaction
        (address destination, uint256 amount) = getTransactionDetails(transactionId);

        // Transfer the specified amount to the destination address
        require(
            address(this).balance >= amount,
            "Insufficient balance in the contract"
        );
        (bool success, ) = payable(destination).call{value: amount}("");
        require(success, "Transaction execution failed");

        // Mark the transaction as executed
        approvals[transactionId][owner1] = true;
        approvals[transactionId][owner2] = true;

        // Emit an event for the executed transaction
        emit TransactionExecuted(transactionId, destination, amount);
    }

    // Function to get the details of a transaction
    function getTransactionDetails(uint256 /* transactionId */)
    internal
    view
    returns (address destination, uint256 amount)
    {

    }

}
