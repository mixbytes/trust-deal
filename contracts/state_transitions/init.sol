pragma solidity 0.5.7;

import './base.sol';

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
        require(feeBPS > 0 && feeBPS < 10000, "Fee BPS could be only in range (0, 10000)");
        require(reviewTimeoutSeconds > 60, "Reviewer decision duration should be gt 0"); // todo 1 minute?

        reviewer = dealReviewer;
        reviewerFeeBPS = feeBPS;
        reviewerDecisionDuration = reviewTimeoutSeconds;

        currentState = States.PROPOSED_REVIEWER;
        emit ReviewerProposed(reviewer, reviewerFeeBPS, reviewerDecisionDuration);
    }
}