pragma solidity 0.5.7;

import "../../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

import './base.sol';
import '../utils/Uint256Caster.sol';

contract DealIterationStateLogic is BaseDealStateTransitioner {
    using Uint256Caster for uint256;
    using SafeMath for uint32;
    using SafeMath for uint256;

    // TODO view functions to events

    event LoggedWork(address employee, uint32 logTimestamp, uint32 workMinutes, string info);
    event IterationFinished(uint32 when);

    function logWork(uint32 logTimestamp, uint32 workMinutes, string calldata info) external {
        // TODO requirements for logTimestamp?
        require(currentState == States.ITERATION, ERROR_WRONG_STATE_CALL);
        require(isEmployee(msg.sender), "Call from logger, who is not contractors employee");
        require(iterationStart.add(iterationDuration) > now, "Time for logging is out");
        require(bytes(info).length > 0, "Info string is empty");
        require(isNotLoggedOverBudget(msg.sender, workMinutes), "Logged minutes over budget");

        minutesDelivered = uint32(workMinutes.add(minutesDelivered)); // TODO to event
        contractorsReward = getNewlyCountedTotalCost(msg.sender, workMinutes);
        emit LoggedWork(msg.sender, logTimestamp, workMinutes, info);
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

    function isEmployee(address logger) internal view returns (bool) {
        return getLoggerRate(logger) != 0;
    }

    function getLoggerRate(address logger) internal view returns (uint256) {
        mapping (address => uint256) storage e = applications[contractor].employeesRates;
        return e[logger];
    }

    function isNotLoggedOverBudget(address logger, uint32 workMinutes)
        internal
        view
        returns (bool)
    {
        uint256 budgetWithoutFees = getBudgetWithoutFees();
        uint256 newlyCountedTotalCost = getNewlyCountedTotalCost(logger, workMinutes);
        return budgetWithoutFees > newlyCountedTotalCost;

    }

    function getBudgetWithoutFees() internal view returns (uint256) {
        uint256 reviewerFeeAmount = dealBudget.mul(reviewerFeeBPS).div(10000);
        uint256 platformFeeAmount = dealBudget.mul(platformFeeBPS).div(10000);

        return dealBudget.sub(reviewerFeeAmount).sub(platformFeeAmount);
    }

    function getNewlyCountedTotalCost(address logger, uint32 workMinutes)
        internal
        view
        returns (uint256)
    {
        uint256 loggerRate = getLoggerRate(logger);
        uint256 loggerCosts = workMinutes.mul(loggerRate).div(60);
        return contractorsReward.add(loggerCosts);
    }
}