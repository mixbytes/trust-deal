pragma solidity 0.5.7;

import './init.sol';
import './proposedReviewer.sol';
import './rfp.sol';
import './wait4deposit.sol';
import './iteration.sol';
import './review.sol';

contract MainDealStateTransitioner is DealReviewStateLogic,
    DealIterationStateLogic,
    DealWait4DepositStateLogic,
    DealRFPStateLogic,
    DealProposedReviewerStateLogic,
    DealInitStateLogic
{
    // Mocks

    function getIterationStat() external view returns (
        uint currentNumber,
        uint minutesLogged,
        uint remainingBudget,
        uint spentBudget
    ) {
        return (0,0,0,0);
    }

    function getTotalStat() external view returns (
        uint minutesLogged,
        uint spentBudget
    ) {
        return (0,0);
    }
}