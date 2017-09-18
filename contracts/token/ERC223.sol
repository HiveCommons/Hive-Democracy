pragma solidity ^0.4.14;

import "./ERC20.sol";

contract ERC223 is ERC20 { 
    uint256 public decimals;
    string public name;
    string public symbol;
    event Transfer(address indexed from, address indexed to, uint256 value, bytes data);
    function transfer(address _to, uint _value, bytes _data) returns (bool ok);
}