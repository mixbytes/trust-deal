pragma solidity 0.5.7;

import '../node_modules/openzeppelin-solidity/contracts/token/ERC20/IERC20.sol'; // TODO tmp
import './ITMIterativeDeal.sol';
import './IDealVersioning.sol';

contract DealDataRows {
    string taskDescription;

    address client;
    address contractor;
    address reviewer;

    IERC20 public dealToken;

    uint16 reviewerFeeBPS;
    uint16 platformFee; // TODO

    uint32 iterationDuration;

    // TODO duration was choosed, because using final timestamp (deadline) causes multiple checks in every state that now() > deadline
    uint32 reviewerDecisionDuration;
    uint32 reviewerDecisionTimeIntervalStart;
}

contract BaseDealStateTransitioner is DealDataRows, ITMIterativeDeal {
    modifier onlyClient {
        require(msg.sender == client, "Only clients action");
        _;
    }

    modifier onlyReviewer {
        require(msg.sender == reviewer, "Only chosen reviewer action");
        _;
    }

    States currentState;

    function getState() external view returns (States) {
        return currentState;
    }

    function init(string calldata task, uint32 iterationTimeSeconds, IERC20 paymentToken)
        external
        onlyClient
    {
        require(currentState == States.CONSTRUCTED, "Call from wrong state");
        require(iterationTimeSeconds > 60 * 60, "Iteration duration should be gt 1 hour");

        taskDescription = task;
        iterationDuration = iterationTimeSeconds;
        dealToken = paymentToken;

        currentState = States.INIT;
    }
}

contract DealInitStateLogic is BaseDealStateTransitioner {
    event ReviewerProposed(address reviewer, uint16 reviewerFeeBPS, uint32 decisionDuration);

    function proposeReviewer(address dealReviewer, uint16 feeBPS, uint32 reviewTimeoutSeconds)
        external
        onlyClient
    {
        require(
            currentState == States.INIT || currentState == States.PROPOSED_REVIEWER,
            "Call from wrong state"
        );
        require(dealReviewer != address(0), "Address can't be zero");
        require(feeBPS > 0 && feeBPS < 10000, "Fee can be only from 1 to 9");
        require(reviewTimeoutSeconds > 60, "Reviewer decision duration should be gt 0"); // todo 1 minute?

        reviewer = dealReviewer;
        reviewerFeeBPS = feeBPS;
        reviewerDecisionDuration = reviewTimeoutSeconds;

        currentState = States.PROPOSED_REVIEWER;
        emit ReviewerProposed(reviewer, reviewerFeeBPS, reviewerDecisionDuration);
    }
}

contract DealProposedReviewerStateLogic is BaseDealStateTransitioner {
    event ReviewerAcceptedConditions(address reviewer);
    event ReviewerDeclinedConditions(address reviewer);

    function reviewerJoins(bool willJoinTheDeal) external {
        if (willJoinTheDeal) {
            _acceptReviewConditions();
        } else {
            _declineReviewConditions();
        }
    }

    function _acceptReviewConditions() internal onlyReviewer {
        require(currentState == States.PROPOSED_REVIEWER, "Call from wrong state");

        currentState = States.RFP;
        emit ReviewerAcceptedConditions(reviewer);
    }

    function _declineReviewConditions() internal onlyReviewer {
        require(currentState == States.PROPOSED_REVIEWER, "Call from wrong state");

        reviewer = address(0);
        reviewerFeeBPS = 0;
        reviewerDecisionDuration = 0;

        currentState = States.INIT;
        emit ReviewerDeclinedConditions(reviewer);
    }
}

contract MainDealStateTransitioner is DealProposedReviewerStateLogic, DealInitStateLogic {
    // Mocks
    function newApplication(
        string calldata application, address[] calldata addresses, uint[] calldata rates
    )
        external
    {
        1+1;
    }

    function cancelRFP() external {
        1+1;
    }

    function approveApplication(address contractor) external {
        1+1;
    }

    function finishDeal() external {
        1+1;
    }

    function newIteration() external payable {
        1+1;
    }

    function logWork(uint32 work_minutes, string calldata info) external {
        1+1;
    }

    function finishIteration() external {
        1+1;
    }

    function reviewOk() external {
        1+1;
    }

    function reviewFailed() external {
        1+1;
    }
}

contract TMIterativeDeal is MainDealStateTransitioner, IDealVersioning {
    // TODO ETH_TOKEN = address(0)
    constructor() public {
        client = msg.sender;
    }

    function getDealType() external pure returns (string memory) {
        return "TMIterativeDeal";
    }

    function getDealVersion() external pure returns (uint8, uint8, uint16) {
        Version memory v = Version(0,0,1);
        return (v.major, v.minor, v.patch);
    }

}