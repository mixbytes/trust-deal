pragma solidity 0.5.7;

contract DealDataRows {
    string taskDescription;

    address client;
    address developer;
    address reviewer;

    uint256 reviewerFee;

    uint64 dealDeadline;
    uint64 reviewerDesicionDeadline; // TODO maybe use patter from RenderHash: _stateTransitionDeadline
}

contract DealStateTransitioner is DealDataRows {
    enum States {INIT, PROPOSED_REVIEWER, RFP, DEPOSIT_WAIT, ITERATION}
    States public currentState; // TODO maybe handled by event logs?
}

contract Deal is DealStateTransitioner {
    constructor(string memory taskDescr_, uint64 iterationTimeout_) public {
        client = msg.sender;

        taskDescription = taskDescr_;
        dealDeadline = iterationTimeout_;
    }
}