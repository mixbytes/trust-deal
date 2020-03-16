pragma solidity 0.5.7;

import './base.sol';
import '../utils/Uint256Caster.sol';
import "../../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract DealWait4DepositStateLogic is BaseDealStateTransitioner {
    using Uint256Caster for uint256;
    using SafeMath for uint256;

    event DealFunded(uint256 fundingAmount);

    function finishDeal() external onlyClient {
        require(currentState == States.WAIT4DEPOSIT, "Call from wrong state");

        if (address(dealToken) == address(0)) {
            // using ethers, not tokens
            msg.sender.transfer(address(this).balance);
        } else {
            // will revert if `balanceOf` fails
            uint256 balanceOfDeal = dealToken.balanceOf(address(this));
            require(
                dealToken.transfer(msg.sender, balanceOfDeal),
                "Transfering client tokens on deal finish failed"
            );
        }

        currentState == States.END;
        emit DealEndedUp(States.WAIT4DEPOSIT);
    }

    function newIteration(uint256 fundingAmount) external payable onlyClient {
        require(currentState == States.WAIT4DEPOSIT, "Call from wrong state");

        if (address(dealToken) == address(0)) {
            require(msg.value == fundingAmount, "Funded less than stated");
            require(msg.value > 10000 wei, "Funding amount is very little");
        } else {
            require(fundingAmount > 10000, "Funding amount is very little");
            require(
                dealToken.transferFrom(msg.sender, address(this), fundingAmount),
                "Reward lock for iteration failed"
            );
        }

        dealBudget = dealBudget.add(fundingAmount);
        iterationStart = now.toUint32();
        currentState = States.ITERATION;
        emit DealFunded(fundingAmount);
    }
}