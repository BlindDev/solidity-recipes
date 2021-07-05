// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.12 <0.9.0;

/**
Withdrawal from Contracts

The recommended method of sending funds after an effect is using the withdrawal pattern. 
Although the most intuitive method of sending Ether, as a result of an effect, is a direct transfer call, 
this is not recommended as it introduces a potential security risk. You may read more about this on the Security Considerations page.

The following is an example of the withdrawal pattern in practice in a contract where the goal is to send the most money to the contract 
in order to become the “richest”, inspired by King of the Ether.

In the following contract, if you are no longer the richest, you receive the funds of the person who is now the richest.

In contrast, using direct sending may have security risks:
An attacker could trap the contract into an unusable state by causing richest to be the address of a contract that has a receive 
or fallback function which fails (e.g. by using revert() or by just consuming more than the 2300 gas stipend transferred to them). 
That way, whenever transfer is called to deliver funds to the “poisoned” contract, it will fail and thus also becomeRichest will fail, 
with the contract being stuck forever.

If you use the “withdraw” pattern from the first example, the attacker can only cause his or her own withdraw to fail 
and not the rest of the contract’s workings.
 */

contract WithdrawalContract {
  address public richest;
  uint public mostSent;

  mapping (address => uint) pendingWithdrawals;

  constructor() payable {
    richest = msg.sender;
    mostSent = msg.value;
  }

  function  becomeRichest() public payable {
    require(msg.value > mostSent, 'Not enough money sent');

    pendingWithdrawals[richest] += msg.value;
    richest = msg.sender;
    mostSent = msg.value;
  }

  function withdraw() public {
    uint amount = pendingWithdrawals[msg.sender];
    // Remember to zero the pending refund
    // sending to prevent re-entrancy attacks
    pendingWithdrawals[msg.sender] = 0;
    payable(msg.sender).transfer(amount);
  }
}