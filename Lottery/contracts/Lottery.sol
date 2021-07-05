// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Lottery {
    address public manager;
    address[] public players;

    constructor(){
        manager = msg.sender;
    }
    
    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,players)));
    }
    
    function enter() public payable{
        require(msg.value > .01 ether);
        players.push(msg.sender);
    }
    
    function pickWinner()public restricted {
        // require(msg.sender == manager);
        uint index = random() % players.length;
        uint contractBalance = address(this).balance;
        payable(players[index]).transfer(contractBalance);
        players = new address[](0);
    }
    
    modifier restricted(){
        require(msg.sender == manager);
        _;
    }
    
    function getPlayers() public view returns (address[] memory) {
        return players;
    }
}
