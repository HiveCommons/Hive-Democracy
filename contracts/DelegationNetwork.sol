pragma solidity ^0.4.10;

import "./Controlled.sol";
import "./DelegationProxy.sol";

/**
 * @title DelegationNetwork
 * @author Ricardo Guilherme Schmidt (Status Research & Development GmbH)
 * Defines two contolled DelegationProxy chains: vote and veto chains.
 * New layers need to be defined under a unique topic bytes4 topic, and all fall back to root topic (topic 0x0)   
 */
contract DelegationNetwork is Controlled {
    
    mapping (bytes4 => Topic) topics;
    
    struct Topic {
        DelegationProxy voteDelegation;
        DelegationProxy vetoDelegation;
    }
    
    function DelegationNetwork() {
         topics[0x0] = newTopic(0x0, 0x0);
    }
    
    function addTopic(bytes4 topicId, bytes4 parentTopic) onlyController {
        Topic memory parent = topics[parentTopic];
        Topic storage topic = topics[topicId]; 
        address vote = address(parent.voteDelegation);
        address veto = address(parent.vetoDelegation);
        require(address(topic.voteDelegation) == 0x0);
        require(address(topic.vetoDelegation) == 0x0);
        require(vote != 0x0);
        require(veto != 0x0);
        topics[topicId] = newTopic(vote, veto);
    }
    
    function newTopic(address _vote, address _veto) private returns (Topic topic) {
        topic = Topic ({ 
            voteDelegation: new DelegationProxy(_vote),
            vetoDelegation: new DelegationProxy(_veto)
        });
    }

    function getTopic(bytes4 _topicId) public constant returns (DelegationProxy vote, DelegationProxy veto) {
        Topic memory topic = topics[_topicId];
        vote = topic.voteDelegation;
        veto = topic.vetoDelegation;
    }
    
}