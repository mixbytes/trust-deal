pragma solidity 0.5.7;

import './base.sol';

contract DealPaymentsManager is DealDataRows {
    event TransferedRestOfFunds(uint256 funds);
    event DealFunded(uint256 fundingAmount);

    function payRestToClient() internal {
        if (address(dealMeanOfPayment) == address(0)) {
            uint256 restFunds = address(this).balance;
            client.transfer(restFunds);
            emit TransferedRestOfFunds(restFunds);
        } else {
            // will revert if `balanceOf` fails
            uint256 balanceOfDeal = dealMeanOfPayment.balanceOf(address(this));
            // TODO TEST if balanceOfDeal == 0
            require(
                dealMeanOfPayment.transfer(client, balanceOfDeal),
                "Transfering client tokens on deal finish failed"
            );
            emit TransferedRestOfFunds(balanceOfDeal);
        }
    }

    function fundIteration(uint256 fundingAmount) internal {
        // Called only by client, that's why `msg.sender` used instead of `client`.
        if (address(dealMeanOfPayment) == address(0)) {
            require(msg.value > 10000 wei, "Funding amount is very little");
            emit DealFunded(msg.value);
        } else {
            require(fundingAmount > 10000, "Funding amount is very little");
            require(
                dealMeanOfPayment.transferFrom(client, address(this), fundingAmount),
                "Locking funding iteration amount failed"
            );
            emit DealFunded(fundingAmount);
        }
    }

    function rewardActors(
        bool shouldRewardReviewer,
        uint256 platformReward,
        uint256 reviewerReward
    )
        internal
    {
        rewardContractor();
        rewardPlatform(platformReward);
        if (shouldRewardReviewer) rewardReviewer(reviewerReward);
    }

    function rewardContractor() internal {
        sendRewardTo(contractor, contractorsReward);
    }

    function rewardPlatform(uint256 platformFeeAmount) internal {
        sendRewardTo(platform, platformFeeAmount);
    }

    function rewardReviewer(uint256 reviewerFeeAmount) internal {
        sendRewardTo(reviewer, reviewerFeeAmount);
    }

    function sendRewardTo(address payable who, uint256 howMuch) internal {
        if (address(dealMeanOfPayment) == address(0)) {
            who.transfer(howMuch);
        } else {
            require(
                dealMeanOfPayment.transfer(who, howMuch),
                "Reward transfer failed"
            );
        }
    }
}
