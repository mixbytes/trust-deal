pragma solidity 0.5.7;

import '../interfaces/ITMIterativeDeal.sol';
import '../../node_modules/openzeppelin-solidity/contracts/token/ERC20/IERC20.sol'; // TODO tmp

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

    struct Application {
        string description;
        mapping (address=>uint256) employees;
    }
    mapping (address => Application) applications;
}

contract BaseDealStateTransitioner is DealDataRows, ITMIterativeDeal {

    event DealInitialized(
        address who,
        string shortName,
        string task,
        uint32 iterationDuration,
        IERC20 paymentToken
    );

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

    function getClient() external view returns (address) {
        return client;
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
        require(currentState == States.CONSTRUCTED, "Call from wrong state");
        require(iterationTimeSeconds > 60 * 60, "Iteration duration should be gt 1 hour");
        require(
            bytes(shortName).length > 0 && bytes(task).length > 0,
            "Task description and short name can't be empty"
        );

        taskShortName = shortName;
        taskDescription = task;
        iterationDuration = iterationTimeSeconds;
        dealToken = paymentToken;

        currentState = States.INIT;
        emit DealInitialized(msg.sender, shortName, task, iterationTimeSeconds, paymentToken);
    }
}