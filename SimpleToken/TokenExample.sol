// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Token {
    // total supply of tokens
    uint public totalSupply = 10000;
    // public name of token like 'Bitcoin'
    string public name = "My Token";
    // symbol of tokejn, like 'BTC'
    string public symbol = "TKN";
    // defines smallest fraction of token we can transfer
    // 18 - is most common decimals for tokin
    uint public decimals = 18;
    // list of all balances
    mapping (address => uint) public balances;
    //  a user can have allowed addresses to spend some value
    mapping (address => mapping(address => uint)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor () {
        // deploying whole supply of token 
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public view returns (uint) {
        // returns balance of the owner
        return balances[owner];
    }
    
    // 1 * 10 ** 18 - value
    function transfer(address to, uint value) public returns (bool) {
        // checks if there is enought amount in sender balance
        require(balanceOf(msg.sender) >= value, 'balance to low');
        // increments balance of receiver
        balances[to] += value;
        // decrement balance of sender
        balances[msg.sender] -= value;
        // emit the event
        emit Transfer(msg.sender, to, value);
        // return success
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns (bool){
        // checks if there is enought amount in from balance
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        
        // increments balance of receiver
        balances[to] += value;
        // decrement balance of owner
        balances[from] -= value;
        // emit the event
        emit Transfer(from, to, value);
        // return success
        return true;
    }
    
    function approve(address spender, uint value) public returns(bool) {
        // spender is allowed to spend the value from the sender
        allowance[msg.sender][spender] = value;
        // emit the event
        emit Approval(msg.sender, spender, value);
        // return success
        return true;
    }
}