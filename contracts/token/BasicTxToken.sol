pragma solidity ^0.4.14;

/// @title Test token contract - Allows testing of token transfers with multisig wallet.
contract BasicTxToken {

    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value, bytes data, bytes32 tokentxid);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) allowed;
    mapping (bytes32 => Transaction) public transactions;
    uint256 public totalSupply;

    string public name;
    string public symbol;
    uint8 public decimals;

    
    struct Account {

        
    }

    struct Transaction {
        address from;
        address to;
        uint256 value;
        bytes data;
    }
        
    function BasicTxToken(string _name, string _symbol, uint8 _decimals) {
        require(bytes(_name).length > 0);
        require(bytes(_symbol).length > 0);
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }


    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        bytes memory _data;
        return transfer(msg.sender, _to, _value, _data) != 0x0;
    }

    function transfer(address _to, uint256 _value, bytes _data)
        public
        returns (bool success)
    {
        return transfer(msg.sender, _to, _value, _data) != 0x0;
    }

    function transferFrom(address _from, address _to, uint256 _value)
        public
        returns (bool success)
    {
        require(allowed[_from][msg.sender] >= _value);
        allowed[_from][msg.sender] -= _value;
        return transfer(_from, _to, _value) != 0x0;
    }

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)
        constant
        public
        returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }

    function transfer(address _from, address _to, uint256 _value, bytes _data) 
        private 
        returns(bytes32 tokentxid) 
    {
        require(balanceOf[_from] >= _value);
        Transfer(_from, _to, _value);
        tokentxid = keccak256(block.number, _from, _to, _value);
        Transfer(_from, _to, _value, tokentxid);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        transactions[tokentxid] = Transaction({from: _from, to: _to, value: _value, data: _data });   
    }
}
