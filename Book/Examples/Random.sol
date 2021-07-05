// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.12 <0.9.0;

contract Oracle {
  address admin;
  uint public rand;

  constructor() {
    admin = msg.sender;
  }

  function feedRandomness(uint _rand) external {
    require(msg.sender == admin);
    rand = _rand;
  }
}
contract MyContract {

  Oracle oracle;
  uint nonce;
  constructor(address _oracleAddress){
    oracle = Oracle(_oracleAddress);
  }
  function generate(uint mod) internal returns(uint){
    uint rand = uint(keccak256(abi.encodePacked(nonce,oracle.rand,block.timestamp, block.difficulty, msg.sender))) % mod;
    nonce++;

    return rand;
  }
}