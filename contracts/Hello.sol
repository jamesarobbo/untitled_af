// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Hello {
  address private owner;
  string private name;

  constructor () {
    owner = msg.sender;
  }

  function setName (string memory _name) public {
    require (msg.sender == owner, "You are not the owner!");
    name = _name;
  }

  function getName() public view returns (string memory){
    return name;
  }

  function sayHello() public view returns (string memory, string memory){
    return  ("Hello Solidity! My name is: ", name);
  }
}