pragma solidity 0.5.7;

import './base.sol';

contract DealProposedReviewerStateLogic is BaseDealStateTransitioner {
    event ReviewerAcceptedConditions(address reviewer);
    event ReviewerDeclinedConditions(address reviewer);

    function reviewerJoins(bool willJoinTheDeal) external {
        require(currentState == States.PROPOSED_REVIEWER, "Call from wrong state");
        if (willJoinTheDeal) {
            _acceptReviewConditions();
        } else {
            _declineReviewConditions();
        }
    }

    function _acceptReviewConditions() internal onlyReviewer {
        currentState = States.RFP;
        emit ReviewerAcceptedConditions(msg.sender);
    }

    function _declineReviewConditions() internal onlyReviewer {
        reviewer = address(0);
        reviewerFeeBPS = 0;
        reviewerDecisionDuration = 0;

        currentState = States.INIT;
        emit ReviewerDeclinedConditions(msg.sender);
    }
}