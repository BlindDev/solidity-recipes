// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Factory {
    Campaign[] public campaigns;
    
    function createCampaign(uint minimum)public {
        Campaign campaign = new Campaign(minimum, msg.sender);
        campaigns.push(campaign);
    }
    
    function getDeployedCampaigns() public view returns (Campaign[] memory) {
        return campaigns;
    }
}

contract Campaign {
    
    struct Request {
        string description;
        uint value;
        address recipient;
        bool complete;
        uint approvalsCount;
        mapping(address => bool) approvals;
    }
    
    uint numRequests;
    mapping (uint => Request) public requests;
    address public manager;
    uint public minimumContribution;
    uint public approversCount;
    mapping(address => bool) public approvers;
    
    // middleware for manager only 
    modifier restricted(){
        require(msg.sender == manager);
        _;
    }

    constructor(uint minimum, address creator){
        manager = creator;
        minimumContribution = minimum;
    }
    
    function contribute() public payable {
        require(msg.value >= minimumContribution);
        approversCount++;
        approvers[msg.sender] = true;
    }
    
    function createRequest(string memory description, uint value, address recipient) public restricted {
        
        Request storage r = requests[numRequests++];
        r.description = description;
        r.value = value;
        r.recipient = recipient;
        r.complete = false;
        r.approvalsCount = 0;
    }
    
    function approveRequest(uint index) public {
        // get the request
        Request storage request = requests[index];
        // check that the sender is in the aprrovers list
        require(approvers[msg.sender]);
        // check if the sender has not already a vote
        require(!request.approvals[msg.sender]);
        
        // increment an amount of approvals
        request.approvalsCount++;
        // set this person as voted for approval
        request.approvals[msg.sender] = true;
    }
    
    function finalizeRequest(uint index) public restricted {
        // get the request
        Request storage request = requests[index];
        
        // check the amount of approvers 
        require(request.approvalsCount > (approversCount/2)); 
        // check the request is not complete
        require(!request.complete);
        
        // transfer money
        payable(request.recipient).transfer(request.value);
        // mark as complete
        request.complete = true;
        
    }
}