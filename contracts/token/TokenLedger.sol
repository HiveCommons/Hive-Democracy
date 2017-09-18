pragma solidity ^0.4.14;

import "./ERC223.sol";
import "./MiniMeToken.sol";
import "./ERC223Receiver.sol";
/**
* @title TokenLedger 
* @author Ricardo Guilherme Schmidt (Status Research & Development GmbH) 
* Abstract contract for tracking token deposits.
* Token transfers that did not approved and called `receiveApproval` can be tracked by 
**/
contract TokenLedger is ERC223Receiver, ApproveAndCallFallBack {
    
    event Withdrawn(address indexed token, address indexed reciever, uint value);
    event Deposited(address indexed token, address indexed sender, uint value, bytes data);
    event Transfer(address indexed token, address indexed sender, address indexed receiver, uint value);
    mapping (address => mapping (address => uint)) public deposits;
    mapping (address => uint) public tokenBalances;
    
    address[] public tokens;

    uint public nonce;
    
    /**
    * @notice watches for balance in a token contract
    * @param _token the token contract address
    **/   
    function updateInternalBalance(address _token) 
        public
    {
        uint oldBal = tokenBalances[_token];
        uint newBal = ERC20(_token).balanceOf(this);
        require(newBal != oldBal);
        if (newBal > oldBal) {
            register(_token, address(this), newBal - oldBal, new bytes(0));
        } else {
            tokenBalances[_token] = newBal;
        }
    }

    /**
    * @notice ERC23 Token fallback
    * @param _from address incoming token
    * @param _amount incoming amount
    **/    
    function tokenFallback(address _from, uint _amount, bytes _data) {
        register(msg.sender, _from, _amount, _data);
    }
    
    /** 
    * @notice Called MiniMeToken approvesAndCall to this contract, calls deposit.
    * @param _from address incoming token
    * @param _amount incoming amount
    * @param _token the token contract address
    * @param _data (might be used by child classes)
    */ 
    function receiveApproval(address _from, uint256 _amount, address _token, bytes _data) {
        uint _nonce = nonce;
        ERC20 token = ERC20(_token);
        if (!token.transferFrom(_from, this, _amount)) {
            revert();
        }
        if (nonce == _nonce) { //ERC23 not executed _deposited tokenFallback by
            register(_token, _from, _amount, _data);
        }
    }
    

    /**
    * @dev register the deposit in a internal balance (for child contract use)
    **/
    function register(address _token, address _sender, uint _amount, bytes _data) 
        internal 
    {
        require(_token != 0x0);
        Deposited(_token, _sender, _amount, _data);
        nonce++;
        if (tokenBalances[_token] == 0) {
            tokens.push(_token);  
            tokenBalances[_token] = ERC20(_token).balanceOf(this);
        } else {
            tokenBalances[_token] += _amount;
        }
        deposits[_token][_sender] += _amount;
    }
    
    /**
     * @dev transfers the internal deposit balance of `_from` to `_to`
     */
    function transfer(address _token, address _from, address _to, uint _amount) 
        internal 
    {
        require(deposits[_token][_from] >= _amount);
        Transfer(_token, _from, _to, _amount);
        deposits[_token][_from] -= _amount;
        deposits[_token][_to] += _amount;
    }
    
    /**
    * @dev withdraw token amount to dest
    **/
    function withdraw(address _token, address _dest, uint _amount, address _consumer) 
        internal 
        returns (bool) 
    {   
        require(tokenBalances[_token] >= _amount);
        if (_consumer != 0x0) {
            require(deposits[_token][_consumer] >= _amount);
            deposits[_token][_consumer] -= _amount;
        }
        Withdrawn(_token, _dest, _amount);
        tokenBalances[_token] -= _amount;
        return ERC20(_token).transfer(_dest, _amount);
    }

}
