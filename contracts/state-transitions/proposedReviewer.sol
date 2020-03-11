pragma solidity 0.5.7;

import './base.sol';

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