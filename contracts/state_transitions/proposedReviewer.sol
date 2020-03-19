pragma solidity 0.5.7;

import './base.sol';

contract DealProposedReviewerStateLogic is BaseDealStateTransitioner {
    event ReviewerAcceptedConditions(address reviewer);
    event ReviewerDeclinedConditions(address reviewer);

    function reviewerJoins(bool willJoinTheDeal) external {
        require(currentState == States.PROPOSED_REVIEWER, ERROR_WRONG_STATE_CALL);
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
        delete reviewer;
        delete reviewerFeeBPS;
        delete reviewerDecisionDuration;

        currentState = States.INIT;
        emit ReviewerDeclinedConditions(msg.sender);
    }
}