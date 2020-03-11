pragma solidity 0.5.7;

import './init.sol';
import './proposedReviewer.sol';
import './rfp.sol';

contract MainDealStateTransitioner is DealRFPStateLogic,
    DealProposedReviewerStateLogic,
    DealInitStateLogic
{
    // Mocks
    function getApplicationsNumber() external view returns (uint) {
        return 0;
    }

    function getApplication(uint i) external view returns (
        address contractor,
        string memory application,
        address[] memory employees,
        uint[] memory rates
    ) {
        return (client,"",new address[](1),new uint[](1));
    }

    function cancelRFP() external {
        1+1;
    }

    function approveApplication(address contractor) external {
        1+1;
    }

    function finishDeal() external {
        1+1;
    }

    function newIteration() external payable {
        1+1;
    }

    function logWork(uint32 workMinutes, string calldata info) external {
        1+1;
    }

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

    function finishIteration() external {
        1+1;
    }

    function reviewOk() external {
        1+1;
    }

    function reviewFailed() external {
        1+1;
    }
}