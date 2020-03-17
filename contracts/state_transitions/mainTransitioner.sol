pragma solidity 0.5.7;

import './init.sol';
import './proposedReviewer.sol';
import './rfp.sol';
import './wait4deposit.sol';
import './iteration.sol';

contract MainDealStateTransitioner is DealIterationStateLogic,
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

    function getLoggedData() external view returns (
        uint32[] memory iterationNumber,
        uint32[] memory logTimestamp,
        uint32[] memory workMinutes,
        uint32[] memory infoEntryLength,
        string memory concatenatedInfos
    ) {
        return (
            new uint32[](1),
            new uint32[](1),
            new uint32[](1),
            new uint32[](1),
            ""
        );
    }

    function reviewOk() external {
        1+1;
    }

    function reviewFailed() external {
        1+1;
    }
}