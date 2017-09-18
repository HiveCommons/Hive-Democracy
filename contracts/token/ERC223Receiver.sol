pragma solidity ^0.4.14;

contract ERC223Receiver {
    function tokenFallback(address _from, uint _value, bytes _data);
}