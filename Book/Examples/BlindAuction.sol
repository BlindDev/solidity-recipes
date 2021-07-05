// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
The advantage of a blind auction is that there is no time pressure towards the end of the bidding period. 
Creating a blind auction on a transparent computing platform might sound like a contradiction, but cryptography comes to the rescue.

During the bidding period, a bidder does not actually send their bid, but only a hashed version of it. 
Since it is currently considered practically impossible to find two (sufficiently long) values whose hash values are equal, 
the bidder commits to the bid by that. After the end of the bidding period, the bidders have to reveal their bids: 
They send their values unencrypted and the contract checks that the hash value is the same as the one provided during the bidding period.

Another challenge is how to make the auction binding and blind at the same time: 
The only way to prevent the bidder from just not sending the money after they won the auction is to make them send it together with the bid. 
Since value transfers cannot be blinded in Ethereum, anyone can see the value.

The following contract solves this problem by accepting any value that is larger than the highest bid. 
Since this can of course only be checked during the reveal phase, some bids might be invalid, 
and this is on purpose (it even provides an explicit flag to place invalid bids with high value transfers): 
Bidders can confuse competition by placing several high or low invalid bids.
 */

 contract BlindAuction {
   struct Bid {
     bytes32 blindedBid;
     uint deposit;
   }

   address payable public beneficiary;
   uint public biddingEnd;
   uint public revealEnd;
   bool public ended;

   mapping(address => Bid[]) public bids;

   address public highestBidder;
   uint public highestBid;

  //  Allowed withdrawals of previous bids
  mapping(address => uint) pendingReturns;

  event AuctionEnded(address winner, uint highestBid);

  /// Modifiers are a convenient way to validate inputs
  /// to functions. 'onlyBefore' is applied to 'bid' below:
  /// The new function body is the modifier's body where
  /// '_' is replaced by the old function body
  modifier onlyBefore(uint _time) {
    require(block.timestamp < _time);
    _;
  }
  modifier onlyAfter(uint _time) {
    require(block.timestamp > _time);
    _;
  }

  constructor(uint _biddingTime, uint _revealTime, address payable _beneficiary) {
    beneficiary = _beneficiary;
    biddingEnd = block.timestamp + _biddingTime;
    revealEnd = biddingEnd + _revealTime;
  }


  /// Place a blinded bid with '_blindedBid' - 
  /// keccak256(abi.encodePacked(value, fake, secret))
  /// The sent either is only refunded if the bid is correctly
  /// revealed in the revealing phase.
  /// The bid is valid if ether sent together with the bid
  /// is at least 'value' and 'fake' is not true
  /// Setting 'fake' to true and sending not the exact
  /// amount are ways to hide the real bid but still
  /// make the required deposit. The same address can
  /// place multiple bids

  function bid(bytes32 _blindedBid) public payable onlyBefore(biddingEnd) {
    bids[msg.sender].push(Bid({
      blindedBid: _blindedBid,
      deposit: msg.value
    }));
  }

  /// Reveal your blinded bids. You will get a refund for all
  /// correctly blinded invalid bids and for all bids
  /// except for totally highest
  function reveal(uint[] memory _values, bool[] memory _fake, bytes32[] memory _secret) 
  public 
  onlyAfter(biddingEnd)
  onlyBefore(revealEnd) {
    uint length = bids[msg.sender].length;
    require((_values.length == length));
    require((_fake.length == length));
    require((_secret.length == length));

    uint refund;

    for (uint256 index = 0; index < length; index++) {
      Bid storage bidToCheck = bids[msg.sender][index];
      (uint value, bool fake, bytes32 secret) = (_values[index], _fake[index], _secret[index]);

      if (bidToCheck.blindedBid != keccak256(abi.encodePacked(value, fake, secret))) {
        // Bid was not actually revealed
        // DO not refund deposit
        continue;
      }

      refund += bidToCheck.deposit;
      if (!fake && bidToCheck.deposit >= value) {
        if (placeBid(msg.sender, value)) {
          refund -= value;
        }
      }

      // Make it impossible for the sender to re-claim the same deposit
      bidToCheck.blindedBid = bytes32(0);
    }

    payable(msg.sender).transfer(refund);
  }

  /// Withdraw a bid that was overbid
  function withdraw() public {
    uint amount = pendingReturns[msg.sender];

    if (amount > 0) {
      // It is important to set this to zero because the recipient
      // can call this function again as part of the receiving call
      // before 'transfer' returns
      // onditions -> effect -> interaction
      pendingReturns[msg.sender] = 0;
      payable(msg.sender).transfer(amount);
    } 
  }

  /// End the auction and send the highest bid
  /// to the beneficiary
  function auctionEnd() public onlyAfter(revealEnd) {
    require(!ended);

    emit AuctionEnded(highestBidder, highestBid);

    ended = true;
    beneficiary.transfer(highestBid);
  }

  // This is an internal function which means that it
  // can only be called from the contract itself
  // or from derived contracts

  function placeBid(address bidder, uint value) internal returns (bool) {
    if (value <= highestBid) {
      return false;
    }

    if (highestBidder != address(0)) {
      // Refund the previous highest bidder
      pendingReturns[highestBidder] += highestBid;
    }

    highestBid = value;
    highestBidder = bidder;
    return true;
  }
 }