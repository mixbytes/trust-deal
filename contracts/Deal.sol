pragma solidity 0.5.7;

import '../node_modules/openzeppelin-solidity/contracts/token/ERC20/IERC20.sol'; // TODO tmp

contract DealDataRows {
    string taskDescription;

    address client;
    address contractor;
    address reviewer;

    IERC20 public dealToken;

    uint8 reviewerFee; // TODO could change

    uint64 iterationDuration;
    uint64 reviewerDecisionDuration; // TODO опасно ставить параметр конечная временная точка, тк надо будет проверять на каждом состоянии.
    uint64 reviewerDecisionTimeIntervalStart;
}

contract DealStateTransitioner is DealDataRows {
    // TODO changeStateTo функцию как в рендер-хэш
    modifier onlyClient {
        require(msg.sender == client, "Reviwer can be proposed only by client");
        _;
    }
    enum States {INIT, PROPOSED_REVIEWER, RFP, DEPOSIT_WAIT, ITERATION}
    States public currentState;

    function proposeReviewer(address contractor_, uint8 fee_, uint64 decisionDuration)
        external
        onlyClient
    {
        require(
            currentState == States.INIT || currentState == States.PROPOSED_REVIEWER,
            "Call from wrong state"
        );
        require(contractor_ != address(0), "Address can't be zero");
        require(fee_ >= 1 && fee_ <= 9, "Fee can be only from 1 to 9");
        require(decisionDuration > 0, "Reviewer decision duration should be gt 0");

        contractor = contractor_;
        reviewerFee = fee_;
        reviewerDecisionDuration = decisionDuration;

        currentState = States.PROPOSED_REVIEWER;
    }
}

contract Deal is DealStateTransitioner {
    constructor(string memory taskDescr_, uint64 iterationTimeout_, IERC20 dealToken_) public {
        client = msg.sender;

        taskDescription = taskDescr_;
        iterationDuration = iterationTimeout_;
        dealToken = dealToken_;
    }
}