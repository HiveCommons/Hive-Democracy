pragma solidity ^0.4.14;

import "./DelegationProxy.sol";

/** @title SimplePoll
 *  @author Ricardo Guilherme Schmidt
 *  Contract used exclusively to crowdsource stakeholder's opinion on a topic with no active execution. 
 **/
contract SimplePoll {
    
    MiniMeToken public token;
    DelegationProxy public delegation;
    uint public startBlock;
    uint public endBlock;
    uint public minQuorum;
    string public description;
    
    uint public tabulationPosition;
    bool public finalized;
    uint public votesApproved;
    uint public votesRejected;

    mapping (address => uint) public votePosition;
    Vote[] public votes;    
    
    struct Vote {
        address voter;
        bool decision;
    }
    
    function SimplePoll(MiniMeToken _token, DelegationProxy _delegation, uint _startBlock, uint _endBlock, uint _minQuorum, string _description) {
        require(address(_token) != 0x0);
        require(address(_delegation) != 0x0);
        require(block.number < _endBlock);
        require(block.number < _startBlock);
        require(_startBlock < _endBlock);
        require(_minQuorum < _token.totalSupply());
        token = _token;
        delegation = _delegation;
        startBlock = _startBlock;
        endBlock = _endBlock;
        minQuorum = _minQuorum;
        description = _description;
    }
    
    function vote(bool decision) public {
        require(block.number >= startBlock);
        require(block.number <= endBlock);
        uint position = votePosition[msg.sender];
        if (position == 0) {
            position = votes.length;
            votePosition[msg.sender] = position;
            votes.push(Vote({voter: msg.sender, decision: decision}));
        } else {
            votes[position].decision = decision;
        }
    }
    
    function tabulate(uint limit) public {
        require(block.number > endBlock);
        require(!finalized);
        uint totalVoted = votes.length;

        if (limit == 0) {
            limit = totalVoted;    
        }
        require (limit <= totalVoted);
        
        for (uint i = tabulationPosition; i < limit; i++) {
            Vote memory _vote = votes[i];
            uint voteWeight = delegation.influenceOfAt(_vote.voter, token, endBlock);
            if (_vote.decision) {
                votesApproved += voteWeight;
            } else {
                votesRejected += voteWeight;
            }
        }
        tabulationPosition = i;
        if (tabulationPosition == totalVoted) {
            finalized = true;        
        }
    }
    
    function result() public constant returns(bool) {
        require(finalized);
        if (votesApproved < minQuorum) {
            //quorum didn't reached minimal
            return false;
        }
        if (votesApproved <= votesRejected) {
            return false;
        } else { 
            //is at least 50% + 1 of approval;
            return true;
        }
    }
    
}