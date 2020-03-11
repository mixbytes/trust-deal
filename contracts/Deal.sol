pragma solidity 0.5.7;

import '../node_modules/openzeppelin-solidity/contracts/token/ERC20/IERC20.sol'; // TODO tmp

contract DealDataRows {
    string taskDescription;

    address client;
    address contractor;
    address reviewer;

    IERC20 public dealToken;

    uint16 reviewerFeeBPS;

    uint32 iterationDuration;

    // TODO duration was choosed, because using final timestamp (deadline) causes multiple checks in every state that now() > deadline
    uint32 reviewerDecisionDuration;
    uint32 reviewerDecisionTimeIntervalStart;
}

contract BaseDealStateTransitioner is DealDataRows {
    modifier onlyClient {
        require(msg.sender == client, "Only clients action");
        _;
    }

    modifier onlyReviewer {
        require(msg.sender == reviewer, "Only chosen reviewer action");
        _;
    }

    enum States {INIT, PROPOSED_REVIEWER, RFP, DEPOSIT_WAIT, ITERATION}
    States public currentState;
}

contract DealProposedReviewerStateLogic is BaseDealStateTransitioner {
    event ReviewerProposed(address reviewer, uint16 reviewerFeeBPS, uint32 decisionDuration);
    event ReviewerAcceptedConditions(address reviewer);
    event ReviewerDeclinedConditions(address reviewer);

    function proposeReviewer(address reviewer_, uint16 feeBPS_, uint32 decisionDuration)
        external
        onlyClient
    {
        require(
            currentState == States.INIT || currentState == States.PROPOSED_REVIEWER,
            "Call from wrong state"
        );
        require(reviewer_ != address(0), "Address can't be zero");
        require(feeBPS_ >= 1 && feeBPS_ <= 9, "Fee can be only from 1 to 9");
        require(decisionDuration > 0, "Reviewer decision duration should be gt 0");

        reviewer = reviewer_;
        reviewerFeeBPS = feeBPS_;
        reviewerDecisionDuration = decisionDuration;

        currentState = States.PROPOSED_REVIEWER;
        emit ReviewerProposed(reviewer, reviewerFeeBPS, reviewerDecisionDuration);
    }

    function acceptReviewConditions() external onlyReviewer {
        require(currentState == States.PROPOSED_REVIEWER, "Call from wrong state");

        currentState = States.RFP;
        emit ReviewerAcceptedConditions(reviewer);
    }

    function declineReviewConditions() external onlyReviewer {
        require(currentState == States.PROPOSED_REVIEWER, "Call from wrong state");

        reviewer = address(0);
        reviewerFeeBPS = 0;
        reviewerDecisionDuration = 0;

        currentState = States.INIT;
        emit ReviewerDeclinedConditions(reviewer);
    }
}

contract MainDealStateTransitioner is DealProposedReviewerStateLogic {}

contract Deal is MainDealStateTransitioner {
    // TODO ETH_TOKEN = address(0)
    constructor(string memory taskDescr_, uint32 iterationTimeout_, IERC20 dealToken_) public {
        client = msg.sender;

        taskDescription = taskDescr_;
        iterationDuration = iterationTimeout_;
        dealToken = dealToken_;
    }
}