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
{}