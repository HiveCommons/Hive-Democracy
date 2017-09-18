pragma solidity ^0.4.10;

import "../deploy/DelegatedCall.sol";

contract Queen is DelegatedCall {

    address constitution;

    /**
     * @dev defines the address for delegation of calls
     */
    function _getDelegatedContract()
        internal
        returns(address)
        {
            return constitution;
        }


}