pragma solidity ^0.4.12;

import "../Controlled.sol";

/**
 * @title LiveFactory
 * @author Ricardo Guilherme Schmidt (Status Research & Development GmbH)
 * Stores bytecode of contracts and deploy them for you. 
 */
contract LiveFactory is Controlled {
    
    event Created (address indexed creator, address instance, uint version);
    event NewBytecode(uint256 blocknum, bytes4 constructor, bytes stubBytecode);
    bytes4 public constructor;
    mapping (uint => bytes) public stubBytecode;
    mapping (address => mapping(uint => address)) instances;
    uint latest;

    /**
     * @dev configure the new bytecode and constructor for new instances
     */
    function setBytecode(bytes4 _constructor, bytes _stubBytecode) onlyController {
        NewBytecode(block.number, _constructor, _stubBytecode);
        constructor = _constructor;
        stubBytecode[block.number] = _stubBytecode;
        latest = block.number;
    }

    function getInstance(address _creator, uint _blockCreated) constant returns (address) {
        return instances[_creator][_blockCreated];
    }
    
    /**
     * @dev generates a new instance
     */
    function newInstance(bytes data) returns (address) {
         
        //loads last bytecode
        bytes memory bytecode = stubBytecode[latest];    
        uint codelen = bytecode.length;
        
        //allocate memory to fill with contract creation call
        uint createsize = data.length + codelen;
        bytes memory createdata = new bytes(createsize);

        //copy bytecode and data into allocated memory
        uint destptr;
        uint srcptr;
        uint srcptr2;
        assembly {
            destptr := add(createdata, 32)
            srcptr := add(bytecode, 32)
            srcptr2 := add(data, 32)
        }
        memcpy(destptr, srcptr, codelen);
        memcpy(destptr + codelen, srcptr2, data.length);

        //creates the contract
        address newContract;
        assembly {
            newContract := create(0, createdata, createsize)
        }
        Created(msg.sender, newContract, latest);
        return newContract;
    }
 /**
  * @dev generates a new instace, needs to be called with 4bytes equal to constructor
  */
    function () {
        //require source defined
        require(latest != 0);
        
        //require 4bytes equal to defined as constructor
        bytes4 ccheck;
        assembly{
            calldatacopy(ccheck, 0, 4)
        }
        require (ccheck == constructor);
        
        //loads last bytecode
        bytes memory bytecode = stubBytecode[latest];    
        uint codelen = bytecode.length;
        
        //allocate memory to fill with contract creation call
        uint createsize = msg.data.length - 4 + codelen;
        bytes memory createdata = new bytes(createsize);

        //copy bytecode into allocated memory
        uint destptr;
        uint srcptr;
        assembly {
            destptr := add(createdata, 32)
            srcptr := add(bytecode, 32)
        }
        memcpy(destptr, srcptr, codelen);
        
        //copy constructor arguments into allocated memory
        assembly {
            destptr := add(createdata, add(codelen, 32))
            calldatacopy(destptr, 4, calldatasize)
        }

        //creates the contract
        address newContract;
        assembly {
            newContract := create(0, createdata, createsize)
        }
        Created(msg.sender, newContract, latest);
        //returns the address
        assembly {
            return(newContract, 32)
        }
    
    }

    /**
     * @dev copy one by one len amount of bytes from dest pointer to src pointr
     */
    function memcpy(uint dest, uint src, uint len) private {
        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

}