pragma solidity 0.5.7;

import '../node_modules/openzeppelin-solidity/contracts/token/ERC20/IERC20.sol';


/**
 * @dev Interface of a deal
 */
interface ITMIterativeDeal {

    /// @dev state machine of a deal
    enum States {CONSTRUCTED, INIT, PROPOSED_REVIEWER, RFP, WAIT4DEPOSIT, ITERATION, REVIEW, END}


    /// @dev Current state of the deal.
    function getState() external view returns (States);

    /**
     * @dev The client initializes the deal.
     *
     * @param task task description
     * @param iterationTimeSeconds maximum duration of an iteration (wall clock seconds)
     * @param paymentToken token used for payments
     */
    function init(string calldata task, uint32 iterationTimeSeconds, IERC20 paymentToken) external;


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

    /**
     * @dev A contractor submits an application for the task.
     *
     * @param application application description
     * @param addresses addresses of actors which log the work hours
     * @param rates hourly rates corresponding to the addresses, in payment_token units
     */
    function newApplication(string calldata application, address[] calldata addresses, uint[] calldata rates) external;

    /// @dev The client cancels the deal.
    function cancelRFP() external;

    /// @dev The client approves the application made by `contractor`.
    function approveApplication(address contractor) external;


    // WAIT4DEPOSIT state functions

    /// @dev The client finishes the deal.
    function finishDeal() external;

    /// @dev The client funds a new iteration.
    function newIteration() external payable;


    // ITERATION state functions

    /**
     * @dev One of contractor addresses logs the work.
     *
     * @param work_minutes minutes delivered
     * @param info description of the work done
     */
    function logWork(uint32 work_minutes, string calldata info) external;

    /// @dev Signals to finish the current iteration and start a review.
    function finishIteration() external;


    // REVIEW state functions

    /// @dev Signals that work can be continued.
    function reviewOk() external;

    /// @dev Signals that the contractor can no longer work on the deal.
    function reviewFailed() external;
}
