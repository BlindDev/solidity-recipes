// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
Simple Open Auction

The general idea of the following simple auction contract is that everyone can send their bids during a bidding period. 
The bids already include sending money / Ether in order to bind the bidders to their bid. 
If the highest bid is raised, the previously highest bidder gets their money back. 
After the end of the bidding period, the contract has to be called manually for the beneficiary to receive their money 
- contracts cannot activate themselves.
*/

contract SimpleAuction {

  // Parameters if the auction.
  // Times are either absolute unix timestamps
  // (seconds since 1970-01-01)
  // or time periods in seconds

  address payable public beneficiary;
  uint public auctionEndTime;

  // Current state of the auction
  address public highestBidder;
  uint public highestBid;

  // Allowed withdrawals of previous bids
  mapping(address => uint) pendingReturns;

  // Set to true at the end, disallows any change
  // By a default initialized to 'false'
  bool ended;

  // Events that will be permitted on cganges
  event HighestBidIncrased(address bidder, uint amount);
  event AuctionEnded(address winner, uint amount);

  // The following is a so-called natspec comment;
  // recognizable by the thee slashes
  // it will be shown when the user is asked to confirm a transaction
  
  /// Create a simple auction with '_biddingTime'
  /// seconds bidding time ion behalf of the
  /// benificiary address '_beneficiary'
  constructor(uint _biddingTime, address payable _beneficiary){
    beneficiary = _beneficiary;
    auctionEndTime = block.timestamp +_biddingTime;

  }  

  /// Bid on the auction with the value sent
  /// together with this transaction
  /// The value will only be refunded
  /// if the auction is not won
  function bid() public payable {
    // No arguments are necessary
    // all infirmation is already 
    // a part of transaction
    // The keyword 'payable' is required
    // for the function to be able to receive Ether

    // Revert the call if the bidding period is over
    require(block.timestamp <= auctionEndTime, 'Auction already ended');

    // If the bid is not higher, send the money back
    // (the failing require will revert all changes
    // in this function execution including
    // it having received the money)
    require(msg.value > highestBid, 'There already is a higher bid');

    if (highestBid != 0) {
      // Sending back money by simply using
      // highestBidder.send(highestBid) is  security risk
      // because it could execute an unstructed contract
      // It is always safer to let the recipients
      // withdrawal their money themselves
      pendingReturns[highestBidder] += highestBid;
    }

    highestBidder = msg.sender;
    highestBid = msg.value;
    emit HighestBidIncrased(msg.sender, msg.value);
  }

  /// Withdraw a bid that was overbid
  function withdraw() public returns (bool) {
    uint amount = pendingReturns[msg.sender];
    if (amount > 0) {
      // It is important to set this to zero
      // because the recipient can call this function again
      // as part of the receiving call before 'send' returns

      pendingReturns[msg.sender] = 0;

      if(!payable(msg.sender).send(amount)){
        // No need to call throw here
        // just reset the amount owing
        pendingReturns[msg.sender] = amount;
        return false;
      }
    }

    return true;
  } 

  /// End the auction and send the highest bid
  /// to the beneficiary
  function auctionEnd() public {
    // It is a good guideline to structure 
    // functions that interract 
    // with orhter contracts (i.e. the call functions or send Ether)
    // into three phases:
    // 1. checking conditions
    // 2. performing actions (potentially changing conditions)
    // 3. interracting with other contracts

    // If these phases are mixed up, the other contract could call
    // back into the current contract and modify the state or cause
    // effects (either payout) to be performed multiple times

    // If functions called internally include interaction with external
    // contracts, they also have to be considered interaction with
    // external contracts 

    // 1. Conditions
    require(block.timestamp >= auctionEndTime, 'Auction not yet ended.');
    require(!ended, 'auctionEnd has already been called');

    // 2. Effects
    ended = true;
    emit AuctionEnded(highestBidder, highestBid);

    // 3. Interaction
    beneficiary.transfer(highestBid);
  }
}