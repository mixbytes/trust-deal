pragma solidity 0.5.7;

import '../node_modules/openzeppelin-solidity/contracts/token/ERC20/IERC20.sol'; // TODO tmp
import './interfaces/ITMIterativeDeal.sol';
import './interfaces/IDealVersioning.sol';

contract DealDataRows {
    string taskShortName;
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

    function init(
        string calldata shortName,
        string calldata task,
        uint32 iterationTimeSeconds,
        IERC20 paymentToken
    )
        external
        onlyClient
    {
        // TODO check strings for emptiness
        require(currentState == States.CONSTRUCTED, "Call from wrong state");
        require(iterationTimeSeconds > 60 * 60, "Iteration duration should be gt 1 hour");

        taskShortName = shortName;
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

    function getReviewer() external view returns (address) {
        return reviewer;
    }

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
    function newApplication(string calldata application, address[] calldata employees, uint[] calldata rates) external {
        1+1;
    }

    function getApplicationsNumber() external view returns (uint) {
        return 0;
    }

    function getApplication(uint i) external view returns (
        address contractor,
        string memory application,
        address[] memory employees,
        uint[] memory rates
    ) {
        return (client,"",new address[](1),new uint[](1));
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

    function logWork(uint32 workMinutes, string calldata info) external {
        1+1;
    }

    function getIterationStat() external view returns (
        uint currentNumber,
        uint minutesLogged,
        uint remainingBudget,
        uint spentBudget
    ) {
        return (0,0,0,0);
    }

    function getTotalStat() external view returns (
        uint minutesLogged,
        uint spentBudget
    ) {
        return (0,0);
    }

    function getLoggedData() external view returns (
        uint32[] memory iterationNumber,
        uint32[] memory logTimestamp,
        uint32[] memory workMinutes,
        uint32[] memory infoEntryLength,
        string memory concatenatedInfos
    ) {
        return (
            new uint32[](1),
            new uint32[](1),
            new uint32[](1),
            new uint32[](1),
            ""
        );
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

    function getClient() external view returns (address) {
        return client;
    }

    function getDealType() external pure returns (string memory) {
        return "TMIterativeDeal";
    }

    function getDealVersion() external pure returns (uint8, uint8, uint16) {
        Version memory v = Version(0,0,1);
        return (v.major, v.minor, v.patch);
    }

    function getInfo() external view returns (
        States state,
        address client,
        string memory shortName,
        string memory task,
        uint32 iterationTimeSeconds,
        IERC20 paymentToken,
        address dealReviewer,
        uint16 feeBPS,
        uint32 reviewTimeoutSeconds
    ) {
        return (
            currentState,
            client,
            taskShortName,
            taskDescription,
            iterationDuration,
            dealToken,
            reviewer,
            reviewerFeeBPS,
            reviewerDecisionDuration
        );
    }
}