pragma solidity ^0.4.10;

import "../DelegationNetwork.sol";
import "../token/TokenLedger.sol";
import "../token/HoneyToken.sol";

contract Honeycomb is TokenLedger {
 
   
    MiniMeToken public honey;
    DelegationNetwork public network;
    uint public capacity = 0;

    
    function Honeycomb(DelegationNetwork _network, MiniMeToken _honey){
        nectar = _nectar;
        honey = new HoneyToken();
        rootTopic = Topic ( { voteDelegation: new DelegationProxy(0x0), vetoDelegation: new DelegationProxy(0x0)});
    }

    Proposal[] proposals;
    
    struct Proposal { 
        bytes4 topic;
        address destination;
        uint value;
        bytes data;
        uint blockStart;
        uint blockEnd;
        
        Vote[] votes;
        mapping(address => VoteLog) voteLog;
        
        mapping(uint8 => uint) results;
        uint tabulationPosition;
        bool tabulated;
        bool approved;
        bool executed;
    }
        
    struct VoteLog {
        bool voted;
        uint index;
    }
    
    enum Vote { 
        Abstention, 
        Veto,  
        Approval 
    }
     

    function vote(uint _proposal, Vote _vote) {
        Proposal storage proposal = proposals[_proposal];
        require(block.number >= proposal.blockStart);
        require(block.number <= proposal.blockEnd);
        VoteLog storage voteLog = proposal.voteLog;
        if (voteLog.voted) {
            proposal.votes[voteLog.index] = _vote;
        } else {
            voteLog.voted = true;
            voteLog.index = votes.length;
            proposal.votes.push(_vote);
        }
    }


    function depositHoney(bytes _data){
        uint amount = honey.allowance(msg.sender, this);
        receiveApproval(msg.sender, amount, address(nectar), _data);
    }
    

}