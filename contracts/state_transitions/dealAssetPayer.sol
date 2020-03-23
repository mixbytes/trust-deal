pragma solidity 0.5.7;

import "../../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

import './base.sol';

contract DealPaymentsManager is DealDataRows {
    using SafeMath for uint256;

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

    function increaseDealBudget(uint256 fundingAmount) internal {
        checkFundedAmount(fundingAmount);
        dealBudget = dealBudget.add(fundingAmount);
    }

    function checkFundedAmount(uint256 fundingAmount) internal {
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
        bool shouldRewardReviewer
    )
        internal
    {
        rewardContractor();

        (uint256 platformReward, uint256 reviewerReward) = getPlatformReviewerRewards();
        rewardPlatform(platformReward);
        if (shouldRewardReviewer) rewardReviewer(reviewerReward);

        uint256 contractorsReward = budgetSpentOnIteration[iterationNumber];
        dealBudget = dealBudget.sub(
            contractorsReward.add(platformReward).add(reviewerReward)
        );
    }

    function rewardContractor() internal {
        uint256 contractorsReward = budgetSpentOnIteration[iterationNumber];
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
            require(dealMeanOfPayment.transfer(who, howMuch), errorMsg);
        }
    }

    function getFeesTotalAmount() internal view returns (uint256) {
        // copy-past with review state function
        (uint256 platformReward, uint256 reviewerReward) = getPlatformReviewerRewards();
        return platformReward.add(reviewerReward);
    }

    function getPlatformReviewerRewards() internal view returns (uint256, uint256) {
        uint256 reviewerFeeAmount = dealBudget.mul(reviewerFeeBPS).div(10000);
        uint256 platformFeeAmount = dealBudget.mul(platformFeeBPS).div(10000);
        return (platformFeeAmount, reviewerFeeAmount);
    }
}
