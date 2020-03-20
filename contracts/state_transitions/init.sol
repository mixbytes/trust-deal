pragma solidity 0.5.7;

import './base.sol';

contract DealInitStateLogic is BaseDealStateTransitioner {
    event ReviewerProposed(address reviewer, uint16 reviewerFeeBPS, uint32 decisionDuration);

    function proposeReviewer(
        address payable reviewerCandidate,
        uint16 feeBPS,
        uint32 reviewIntervalSeconds
    )
        external
        onlyClient
    {
        require(
            currentState == States.INIT || currentState == States.PROPOSED_REVIEWER,
            ERROR_WRONG_STATE_CALL
        );
        require(reviewerCandidate != address(0), ERROR_ZERO_ADDRESS);
        require(feeBPS > 0 && feeBPS < 10000, "Fee BPS could be only in range (0, 10000)");
        require(reviewIntervalSeconds > 60, "Reviewer decision duration should be gt 1 min");

        reviewer = reviewerCandidate;
        reviewerFeeBPS = feeBPS;
        reviewerDecisionDuration = reviewIntervalSeconds;

        currentState = States.PROPOSED_REVIEWER;
        emit ReviewerProposed(reviewer, reviewerFeeBPS, reviewerDecisionDuration);
    }
}