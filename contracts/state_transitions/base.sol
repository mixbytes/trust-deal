pragma solidity 0.5.7;

import '../../node_modules/openzeppelin-solidity/contracts/token/ERC20/IERC20.sol';

import '../interfaces/ITMIterativeDeal.sol';
import '../interfaces/ITMIterativeDealsRegistry.sol';

contract DealDataRows {
    string taskShortName;
    string taskDescription;

    address payable client;
    address payable contractor;
    address payable reviewer;
    address payable platform;

    IERC20 public dealMeanOfPayment;
    ITMIterativeDealsRegistry registry;

    uint16 reviewerFeeBPS; // instead of reviewerReward
    uint16 platformFeeBPS; // instead of platformReward

    uint32 iterationDuration;
    uint32 iterationStart; // timestamp
    uint32 iterationNumber;

    uint32 reviewerDecisionDuration;
    uint32 reviewerDecisionTimeIntervalStart; // timestamp

    uint256 dealBudget;
    mapping (uint32 => uint32) minutesDeliveredOnIteration;
    mapping (uint32 => uint256) spentContractorsRewardsOnIteration;
    mapping (uint32 => uint256) spentReviewerRewardsOnIteration;
    mapping (uint32 => uint256) spentPlatformRewardsOnIteration;

    struct Application {
        string description;
        mapping (address => uint256) employeesRates;
        mapping (address => bool) isStatedEmployeeFlag;
    }
    mapping (address => Application) applications;
}

contract BaseDealStateTransitioner is DealDataRows, ITMIterativeDeal {

    string internal constant ERROR_WRONG_STATE_CALL = "Call from wrong state";
    string internal constant ERROR_ZERO_ADDRESS = "Address value can't be zero";

    modifier onlyClient {
        require(msg.sender == client, "Only clients action");
        _;
    }

    modifier onlyReviewer {
        require(msg.sender == reviewer, "Only chosen reviewer action");
        _;
    }

    States currentState;

    event DealInitialized(
        address who,
        string shortName,
        string task,
        uint32 iterationDuration,
        IERC20 meanOfPayment
    );

    function getState() external view returns (States) {
        return currentState;
    }

    function getClient() external view returns (address) {
        return client;
    }

    function init(
        string calldata shortName,
        string calldata task,
        uint32 iterationTimeSeconds,
        IERC20 meanOfPayment
    )
        external
        onlyClient
    {
        require(currentState == States.CONSTRUCTED, ERROR_WRONG_STATE_CALL);
        require(iterationTimeSeconds > 60 * 60, "Iteration duration should be gt 1 hour");
        require(
            bytes(shortName).length > 0 && bytes(task).length > 0,
            "Task description and short name can't be empty"
        );

        taskShortName = shortName;
        taskDescription = task;
        iterationDuration = iterationTimeSeconds;
        dealMeanOfPayment = meanOfPayment;

        currentState = States.INIT;

        registry.setDealForClient(msg.sender, ITMIterativeDeal(address(this)));

        emit DealInitialized(msg.sender, shortName, task, iterationTimeSeconds, meanOfPayment);
    }
}