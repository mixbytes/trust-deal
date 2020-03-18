pragma solidity 0.5.7;

import '../../node_modules/openzeppelin-solidity/contracts/token/ERC20/IERC20.sol';


/**
 * @dev Interface of a deal
 */
interface ITMIterativeDeal {

    /// @dev state machine of a deal
    enum States {CONSTRUCTED, INIT, PROPOSED_REVIEWER, RFP, WAIT4DEPOSIT, ITERATION, REVIEW, END}
    event DealEndedUp(States when);

    /// @dev Current state of the deal.
    function getState() external view returns (States);

    /// @dev Client of the deal.
    function getClient() external view returns (address);

    /**
     * @dev The client initializes the deal.
     *
     * @param shortName short name
     * @param task task description
     * @param iterationTimeSeconds maximum duration of an iteration (wall clock seconds)
     * @param meanOfPayment mean of payment for the deal. If address(0), then ethers are used.
     */
    function init(string calldata shortName, string calldata task, uint32 iterationTimeSeconds, IERC20 meanOfPayment)
        external;


    // INIT state functions

    /**
     * @dev The client proposes participation to a reviewer.
     *
     * @param dealReviewer proposed reviewer
     * @param feeBPS reviewer fee in basis points
     * @param reviewTimeoutSeconds timeout for the review phase
     */
    function proposeReviewer(address dealReviewer, uint16 feeBPS, uint32 reviewTimeoutSeconds) external;


    // PROPOSED_REVIEWER state functions

    /**
     * @dev The reviewer either accepts or declines the deal.
     *
     * @param willJoinTheDeal if true, the reviewer joins the deal and will act as a reviewing party from now on
     */
    function reviewerJoins(bool willJoinTheDeal) external;


    // RFP state functions

    /// @dev Reviewer of the deal.
    function getReviewer() external view returns (address);

    /// @dev Basic info about the deal.
    function getInfo() external view returns (
        States state,
        address dealClient,
        string memory shortName,
        string memory task,
        uint32 iterationTimeSeconds,
        IERC20 meanOfPayment,
        address dealReviewer,
        uint16 feeBPS,
        uint32 reviewTimeoutSeconds
    );

    /**
     * @dev A contractor submits an application for the task.
     *
     * @param application application description
     * @param workers addresses of actors which log the work hours
     * @param rates hourly rates corresponding to the addresses, in payment_token units
     */
    function newApplication(string calldata application, address[] calldata workers, uint256[] calldata rates) external;

    /// @dev Emitted when a new application is added by `contractor` (not indexed on purpose).
    event ApplicationAdded(address contractor, string application, address[] workers, uint256[] rates);

    /// @dev The client cancels the deal.
    function cancelRFP() external;

    /// @dev The client approves the application made by `contractorForDeal`.
    function approveApplication(address contractorForDeal) external;


    // WAIT4DEPOSIT state functions

    /// @dev The client finishes the deal.
    function finishDeal() external;

    /// @dev The client funds a new iteration.
    function newIteration(uint256 fundingAmount) external payable;


    // ITERATION state functions

    /**
     * @dev One of contractor addresses logs the work.
     *
     * @param logTimestamp when the work was performed
     * @param workMinutes minutes delivered
     * @param info description of the work done
     */
    function logWork(uint32 logTimestamp, uint32 workMinutes, string calldata info) external;

    event LoggedWork(uint32 indexed iterationNumber, uint32 logTimestamp, uint32 workMinutes, string info);

    /// @dev Stat of the current iteration.
    function getIterationStat() external view returns (
        uint currentNumber,
        uint minutesLogged,
        uint remainingBudget,
        uint spentBudget
    );

    /// @dev Lifetime stat of the deal.
    function getTotalStat() external view returns (
        uint minutesLogged,
        uint spentBudget
    );

    /// @dev Signals to finish the current iteration and start a review.
    function finishIteration() external;


    // REVIEW state functions

    /// @dev Signals that work can be continued.
    function reviewOk() external;

    /// @dev Signals that the contractor can no longer work on the deal.
    function reviewFailed() external;
}
