pragma solidity ^0.8.7; // version that we used.
// SPDX-License-Identifier: MIT

contract FeeCollector {
    address public owner; // the owner's address.
    uint256 public balance; // the amount of money in the account of the owner.

    constructor () {
        owner = msg.sender; // The contract's deployer is the owner.

    }
    
    receive() payable external { // this function is called when someone transfers money to the contract.
        balance += msg.value; // When someone sends money to the contract, the balance is raised by msg.value.
    }

    function withdraw(uint amount, address payable destAddr) public { // this function withdraws money from "destAddr" based on "amount".
    
        require(msg.sender == owner, "Only owner can withdraw");  // Because the withdraw function is public, add a layer of security by checking if it is called by the owner.
        require(amount <= balance, "Insufficient funds"); // Check to determine whether the account has enough money to withdraw the specified amount.
        destAddr.transfer(amount); // If the conditions are satisfied, transmit "amount" to destAddr.
        balance -= amount; // reduce the balance by the amount withdrawn.
    }

}