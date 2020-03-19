pragma solidity 0.5.7;

import "../../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import '../../node_modules/openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol';

import './base.sol';
import './dealAssetPayer.sol';
import '../utils/Uint256Caster.sol';

contract DealWait4DepositStateLogic is BaseDealStateTransitioner,
    DealPaymentsManager,
    ReentrancyGuard
{
    using Uint256Caster for uint256;
    using SafeMath for uint32;
    using SafeMath for uint256;

    /**
     * @notice Actually, it could be considered safe against re-entrancy,
     * because function transfers rest of balance.
     */
    function finishDeal() external onlyClient nonReentrant {
        require(currentState == States.WAIT4DEPOSIT, ERROR_WRONG_STATE_CALL);

        payRestToClient();

        currentState == States.END;
        emit DealEndedUp(States.WAIT4DEPOSIT);
    }

    function newIteration(uint256 fundingAmount) external payable onlyClient {
        require(currentState == States.WAIT4DEPOSIT, ERROR_WRONG_STATE_CALL);

        checkFundedAmount(fundingAmount);

        dealBudget = dealBudget.add(fundingAmount);
        iterationStart = now.toUint32();
        currentState = States.ITERATION;
    }
}