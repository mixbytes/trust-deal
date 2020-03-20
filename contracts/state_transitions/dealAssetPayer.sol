pragma solidity 0.5.7;

import './base.sol';

contract DealPaymentsManager is DealDataRows {
    event TransferedRestOfFunds(uint256 funds);
    event DealFunded(uint256 fundingAmount);

    string private constant ERROR_CLIENT_FUNDS_TRANSFER = "Transfering user ethers on deal finished failed";
    string private constant ERROR_LITTLE_FUNDING_AMOUNT = "Funding amount must be gt 10000";
    string private constant ERROR_REWARD_TRANSFER_FAILED = "Reward transfer failed";

    function payRestToClient() internal {
        uint256 transferingAmount;
        if (address(dealMeanOfPayment) == address(0)) {
            transferingAmount = address(this).balance;
        } else {
            transferingAmount = dealMeanOfPayment.balanceOf(address(this));
        }
        sendAssetsTo(client, transferingAmount, ERROR_CLIENT_FUNDS_TRANSFER);
        emit TransferedRestOfFunds(transferingAmount);
    }

    function checkFundedAmount(uint256 fundingAmount) internal {
        // Called only by client, that's why `msg.sender` used instead of `client`.
        if (address(dealMeanOfPayment) == address(0)) {
            require(msg.value > 10000 wei, ERROR_LITTLE_FUNDING_AMOUNT);
            emit DealFunded(msg.value);
        } else {
            require(fundingAmount > 10000, ERROR_LITTLE_FUNDING_AMOUNT);
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
        sendAssetsTo(contractor, contractorsReward, ERROR_REWARD_TRANSFER_FAILED);
    }

    function rewardPlatform(uint256 platformFeeAmount) internal {
        sendAssetsTo(platform, platformFeeAmount, ERROR_REWARD_TRANSFER_FAILED);
    }

    function rewardReviewer(uint256 reviewerFeeAmount) internal {
        sendAssetsTo(reviewer, reviewerFeeAmount, ERROR_REWARD_TRANSFER_FAILED);
    }

    function sendAssetsTo(address payable who, uint256 howMuch, string memory errorMsg) internal {
        if (address(dealMeanOfPayment) == address(0)) {
            bool success = who.send(howMuch);
            require(success, errorMsg);
        } else {
            require(
                dealMeanOfPayment.transfer(who, howMuch),
                errorMsg
            );
        }
    }
}
