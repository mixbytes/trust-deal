pragma solidity 0.5.7;

import './base.sol';

contract DealWait4DepositStateLogic is BaseDealStateTransitioner {
    function finishDeal() external onlyClient {
        // TODO unfinished
        require(currentState == States.WAIT4DEPOSIT, "Call from wrong state");

        if (address(dealToken) == address(0)) {
            // using ethers, not tokens
            msg.sender.transfer(address(this).balance);
        } else {
            // send tokens
        }

        currentState == States.END;
    }

    function newIteration(uint256 fundingAmount) external payable onlyClient {
        require(currentState == States.WAIT4DEPOSIT, "Call from wrong state");
        require(fundingAmount > 0, "Funding amount is very little"); // TODO minimum?

        if (address(dealToken) == address(0)) {
            require(msg.value == fundingAmount, "Funded less than stated");
        } else {
            require(
                dealToken.transferFrom(msg.sender, address(this), fundingAmount),
                "Reward lock for iteration failed"
            );
        }

        currentState = States.ITERATION;
    }
}