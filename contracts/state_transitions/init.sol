pragma solidity 0.5.7;

import './base.sol';

contract DealInitStateLogic is BaseDealStateTransitioner {
    event ReviewerProposed(address reviewer, uint16 reviewerFeeBPS, uint32 decisionDuration);

    function proposeReviewer(
        address reviewerCandidate,
        uint16 feeBPS,
        uint32 reviewIntervalSeconds
    )
        external
        onlyClient
    {
        require(
            currentState == States.INIT || currentState == States.PROPOSED_REVIEWER,
            "Call from wrong state"
        );
        require(reviewerCandidate != address(0), "Address can't be zero");
        require(feeBPS > 0 && feeBPS < 10000, "Fee BPS could be only in range (0, 10000)");
        // TODO 1 minute?
        require(reviewIntervalSeconds > 60, "Reviewer decision duration should be gt 60 sec");

        reviewer = reviewerCandidate;
        reviewerFeeBPS = feeBPS;
        reviewerDecisionDuration = reviewIntervalSeconds;

        currentState = States.PROPOSED_REVIEWER;
        emit ReviewerProposed(reviewer, reviewerFeeBPS, reviewerDecisionDuration);
    }
}