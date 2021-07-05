// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract ContractA {
  function foo(uint arg) external {
    // do smth
  }
}

contract ContractB {
  function foo(uint arg) external {
    // do smth
  }
}

contract Utils {
  function groupExecute(uint argA, uint argB) public{
    ContractA(0x0).foo(argA);
    ContractB(0x0).foo(argB);
  }
}