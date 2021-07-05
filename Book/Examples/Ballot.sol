// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
“The following contract is quite complex, but showcases a lot of Solidity’s features. 
It implements a voting contract. Of course, the main problems of electronic voting is how to assign voting rights to the correct persons and how to prevent manipulation. 
We will not solve all problems here, but at least we will show how delegated voting can be done so that vote counting is automatic and completely transparent at the same time.

The idea is to create one contract per ballot, providing a short name for each option. 
Then the creator of the contract who serves as chairperson will give the right to vote to each address individually.

The persons behind the addresses can then choose to either vote themselves or to delegate their vote to a person they trust.

At the end of the voting time, winningProposal() will return the proposal with the largest number of votes.”
*/

/// @title Voting with delegation.
contract Ballot {

  // This declares a new complex type which will
  // be used for variables later.
  // It will represent a single voter.

  struct Voter {
    uint weight; // weight is accumulated by delegation
    bool voted; // if true, that person already voted
    address delegate; // person delegated to
    uint vote; // index of the voted proposal
  }

  // this is the type of single proposal
  struct Proposal {
    bytes32 name; // short name up to 32 bytes
    uint voteCount; // number of accumulated votes
  }

  address public chairperson;

  // This declares a state variable that
  // storws a 'Voter' struct for each possible address
  mapping(address => Voter) public voters;


  // A dynamically-sized array of 'Proposals'
  Proposal[] public proposals;

  // Create a new ballot to choose one of 'proposalNames'

  constructor(bytes32[] memory proposalNames) {
    chairperson = msg.sender;
    voters[chairperson].weight = 1;

    // For each of the provided proposal names,
    // create a new proposal object and add it 
    // to the end of the array

    for (uint256 index = 0; index < proposalNames.length; index++) {
      // 'Proposal({...})' creates a temporary
      // Proposal object and 'proposals.push' 
      // appends it to the end of 'propoals'
      proposals.push(Proposal({
        name: proposalNames[index],
        voteCount: 0
      }));
    }
  }

  // Give 'voter' the right to vote on this ballot
  // May only be called by 'chairperson
  function giveRightToVote(address voter) public {
    // If the first argument of 'require' evaluates
    // to 'fasle', execution terminates and all
    // changes to the state and to Ether ballances are reverted.
    // This used to cinsume all gass in old EVM versions, but not enymore.
    // It is often a good idea to use 'require' to check if
    // functions are called correctly
    // As a second argument, you can also provide an 
    // explanation about what went wrong
    require(msg.sender == chairperson,'Only chairperson can give rights to vote');
    require(!voters[voter].voted, 'The voter already voted'); 
    require(voters[voter].weight == 0);

    voters[voter].weight = 1;
  }

  // Delegate your vote to the voter 'to'
  function delegate(address to) public {
    // assign reference
    Voter storage sender = voters[msg.sender];
    require(!sender.voted, 'You already voted');

    require(to != msg.sender, 'Self-delegation is not allowed');

    // Forward the delegation as long as 'to' also delegated
    // In general, such loops are very dangerous
    // because if they run too long, they might
    // need more Gas than is available in a block.
    // In this case, the delegation will not be executed,
    // but in other situations, such loop might
    // cause a contract to get 'stuck' completely

    while (voters[to].delegate != address(0)) {
      to = voters[to].delegate;
      require(to !=msg.sender, 'Found loop in delegation');

      // since 'sender' is a reference, this
      // modifies 'voters[msg.sender].voted'
      sender.voted = true;
      sender.delegate = to;
      Voter storage delegate_ = voters[to];
      if (delegate_.voted) {
        // If the delegate already voted,
        // directly add the number of votes
        proposals[delegate_.vote].voteCount += sender.weight;
      }else{
        // If the delegate did not vote yet,
        //  add to his/her weight
        delegate_.weight += sender.weight;
      }
    }
  }

  // Give your vote (including votes delegated to you)
  // to proposal 'proposals[proposal].name'
  function vote(uint proposal) public {
    Voter storage sender = voters[msg.sender];
    require(sender.weight != 0, 'Has no right to vote');
    require(!sender.voted, 'Already voted');
    sender.voted = true;
    sender.vote = proposal;

    // If 'proposal' is out if the range of the array
    // this will throw automatically and revert all changes
    proposals[proposal].voteCount += sender.weight;
  }

  // @dev Computes the winning proposal taing all
  // previous votes into account
  function winningProposal() public view returns (uint winningProposal_) {

    uint winningVoteCount = 0;

    for (uint256 index = 0; index < proposals.length; index++) {
      if (proposals[index].voteCount > winningVoteCount) {
        winningVoteCount = proposals[index].voteCount;
        winningProposal_ = index;
      }
    }
  }

  // Calls winningProposal() function to get the index
  // of the winner contained in the proposals array
  // and then returns the winner
  function winnerName() public view returns (bytes32 winnerName_) {
    winnerName_ = proposals[winningProposal()].name;
  } 
}