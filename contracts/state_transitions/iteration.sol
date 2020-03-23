pragma solidity 0.5.7;

import "../../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

import './base.sol';
import './dealAssetPayer.sol';
import '../utils/Uint256Caster.sol';

contract DealIterationStateLogic is BaseDealStateTransitioner, DealPaymentsManager {
    using Uint256Caster for uint256;
    using SafeMath for uint32;
    using SafeMath for uint256;

    event IterationFinished(uint32 when);

    function logWork(uint32 logTimestamp, uint32 workMinutes, string calldata info) external {
        require(currentState == States.ITERATION, ERROR_WRONG_STATE_CALL);
        require(isEmployee(msg.sender), "Call from logger, who is not contractors employee");
        uint32 iterationTimeout = uint32(iterationStart.add(iterationDuration));
        require(
            logTimestamp >= iterationStart && logTimestamp < iterationTimeout,
            "Log timestamp should be gt iteration start"
        );
        require(iterationTimeout > now, "Time for logging is out");
        require(bytes(info).length > 0, "Info string is empty");
        require(isNotLoggingOverBudget(msg.sender, workMinutes), "Logged minutes over budget");

        // alias
        mapping (uint32 => uint32) storage mDI = minutesDeliveredOnIteration;
        mDI[iterationNumber] = uint32(mDI[iterationNumber].add(workMinutes));

        budgetSpentOnIteration[iterationNumber] = getNewlyCountedTotalCost(
            msg.sender,
            workMinutes
        );
        emit LoggedWork(iterationNumber, logTimestamp, workMinutes, info);
    }

    function finishIteration() external {
        require(currentState == States.ITERATION, ERROR_WRONG_STATE_CALL);
        require(
            (msg.sender == contractor && iterationStart.add(iterationDuration) > now) ||
            now >= iterationStart.add(iterationDuration),
            "Actor can't finish iteration"
        );

        reviewerDecisionTimeIntervalStart = now.toUint32();
        currentState = States.REVIEW;
        emit IterationFinished(now.toUint32());
    }

    // TODO unfinished
    function getIterationStat() external view returns (
        uint32 currentNumber,
        uint32 minutesLogged,
        uint256 remainingBudget,
        uint256 spentBudget
    ) {
        require(currentState >= States.ITERATION, ERROR_WRONG_STATE_CALL);
        currentNumber = iterationNumber;
        minutesLogged = minutesDeliveredOnIteration[iterationNumber];

        //alias
        mapping (uint32 => uint256) storage bSOI = budgetSpentOnIteration;
        remainingBudget = dealBudget.sub(bSOI[iterationNumber]).sub(getFeesTotalAmount());
        spentBudget = bSOI[iterationNumber].add(getFeesTotalAmount());
    }

    // TODO unfinished
    function getTotalStat() external view returns (
        uint32 totalMinutesLogged,
        uint256 totalSpentBudget
    ) {
        // Not sure if is right requirement
        require(currentState >= States.ITERATION, ERROR_WRONG_STATE_CALL);
        for (uint32 i = 1; i <= iterationNumber; i++) {
            totalMinutesLogged = uint32(totalMinutesLogged.add(minutesDeliveredOnIteration[i]));
            totalSpentBudget = totalSpentBudget.add(
                budgetSpentOnIteration[i].add(getFeesTotalAmount())
            );
        }
    }

    function isEmployee(address logger) internal view returns (bool) {
        return getLoggerRate(logger) != 0;
    }

    function getLoggerRate(address logger) internal view returns (uint256) {
        mapping (address => uint256) storage e = applications[contractor].employeesRates;
        return e[logger];
    }

    function isNotLoggingOverBudget(address logger, uint32 workMinutes)
        internal
        view
        returns (bool)
    {
        uint256 budgetWithoutFees = getBudgetWithoutFees();
        uint256 newlyCountedTotalCost = getNewlyCountedTotalCost(logger, workMinutes);
        return budgetWithoutFees >= newlyCountedTotalCost;
    }

    function getBudgetWithoutFees() internal view returns (uint256) {
        return dealBudget.sub(getFeesTotalAmount());
    }

    function getNewlyCountedTotalCost(address logger, uint32 workMinutes)
        internal
        view
        returns (uint256)
    {
        // alias
        mapping (uint32 => uint256) storage bSOI = budgetSpentOnIteration;

        uint256 loggerRate = getLoggerRate(logger);
        uint256 loggerCosts = workMinutes.mul(loggerRate).div(60);
        return bSOI[iterationNumber].add(loggerCosts);
    }
}