pragma solidity 0.5.7;

contract DealDataRows {
    string taskDescription;

    address client;
    address developer;
    address reviewer;

    uint256 reviewerFee;

    uint64 iterationDuration;
    uint64 reviewerDecisionDuration; // TODO опасно ставить параметр конечная временная точка, тк надо будет проверять на каждом состоянии.
    uint64 reviewerDecisionTimeIntervalStart;
}

contract DealStateTransitioner is DealDataRows {
    enum States {INIT, PROPOSED_REVIEWER, RFP, DEPOSIT_WAIT, ITERATION}
    States public currentState;
}

contract Deal is DealStateTransitioner {
    constructor(string memory taskDescr_, uint64 iterationTimeout_) public {
        client = msg.sender;

        taskDescription = taskDescr_;
        iterationDuration = iterationTimeout_;
    }
}