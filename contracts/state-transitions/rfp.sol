pragma solidity 0.5.7;

import './base.sol';

contract DealRFPStateLogic is BaseDealStateTransitioner {

    function newApplication(
        string calldata application,
        address[] calldata workers,
        uint256[] calldata rates
    )
        external
    {
        require(currentState == States.RFP, "Call from wrong state");

        applications[msg.sender] = Application(application);
        for (uint16 i; i < 100; i++) {
            require(
                workers[i] != address(0) && rates[i] != 0,
                "Wrong application params: address or related rate are equal to 0"
            );
            applications[msg.sender].employees[workers[i]] = rates[i];
        }
    }
}