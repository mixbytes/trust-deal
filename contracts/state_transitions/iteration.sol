pragma solidity 0.5.7;

import './base.sol';

import '../utils/Uint256Caster.sol';
import "../../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract DealIterationStateLogic is BaseDealStateTransitioner {
    using Uint256Caster for uint256;
    using SafeMath for uint32;
    using SafeMath for uint256;

    // TODO view funcs

    event LoggedWork(address employee, uint32 logTimestamp, uint32 workMinutes, string info);

    function logWork(uint32 logTimestamp, uint32 workMinutes, string calldata info) external {
        // TODO requirements for logTimestamp?
        require(currentState == States.ITERATION, "Call from wrong state");
        require(_isEmployee(msg.sender), "Call from logger, who is not contractors employee");
        // TODO save cast from 32 to 256?
        require(iterationStart.add(iterationDuration) > now, "Time for logging is out");
        require(bytes(info).length > 0, "Info string is empty");
        require(_isNotLoggedOverBudget(msg.sender, workMinutes), "Logged minutes over budget");

        minutesDelivered = uint32(workMinutes.add(minutesDelivered)); // TODO log?
        totalCosts = _getNewlyCountedTotalCost(msg.sender, workMinutes);
        emit LoggedWork(msg.sender, logTimestamp, workMinutes, info);
    }

    function finishIteration() external {
        require(currentState == States.ITERATION, "Call from wrong state");
        require(
            (msg.sender == contractor && iterationStart.add(iterationDuration) > now) ||
            now >= iterationStart.add(iterationDuration),
            "Actor can't finish iteration"
        );

        reviewerDecisionTimeIntervalStart = now.toUint32();
        currentState = States.REVIEW;
    }

    function _isEmployee(address logger) internal view returns (bool) {
        return _getLoggerRate(logger) != 0;
    }

    function _getLoggerRate(address logger) internal view returns (uint256) {
        mapping (address => uint256) storage e = applications[contractor].employeesRates;
        return e[logger];
    }

    function _isNotLoggedOverBudget(address logger, uint32 workMinutes)
        internal
        view
        returns (bool)
    {
        uint256 budgetWithoutFees = _getBudgetWithoutFees();
        uint256 newlyCountedTotalCost = _getNewlyCountedTotalCost(logger, workMinutes);
        return budgetWithoutFees > newlyCountedTotalCost;

    }

    function _getBudgetWithoutFees() internal view returns (uint256) {
        uint256 reviewerFeeAmount = dealBudget.mul(reviewerFeeBPS).div(10000);
        // cleane platform fee
        uint256 platformFeeAmount = dealBudget.mul(platformFeeBPS).div(10000);

        return dealBudget.sub(reviewerFeeAmount).sub(platformFeeAmount);
    }

    function _getNewlyCountedTotalCost(address logger, uint32 workMinutes)
        internal
        view
        returns (uint256)
    {
        uint256 loggerRate = _getLoggerRate(logger);
        uint256 loggerCosts = workMinutes.mul(loggerRate).div(60);
        return totalCosts.add(loggerCosts);
    }
}