// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.12 <0.9.0;

contract Random {
  function generate(uint mod) external view returns(uint){
    return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % mod;
  }
}