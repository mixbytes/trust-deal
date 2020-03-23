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

    function updateDealIterationBudget(uint256 fundingAmount, uint32 iteration) internal {
        checkFundedAmount(fundingAmount);
        dealBudget = dealBudget.add(fundingAmount);
        spentPlatformRewardsOnIteration[iteration] = dealBudget.mul(platformFeeBPS).div(10000);
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

    function getPotentialReviewerReward() internal view returns (uint256) {
        return dealBudget.mul(reviewerFeeBPS).div(10000);
    }

    function rewardActors(
        bool shouldRewardReviewer
    )
        internal
    {
        uint256 contractorsReward = spentContractorsRewardsOnIteration[iterationNumber];
        uint256 platformReward = spentPlatformRewardsOnIteration[iterationNumber];
        rewardContractor(contractorsReward);
        rewardPlatform(platformReward);

        uint256 reviewerReward;
        if (shouldRewardReviewer) {
            defineReviewerReward();
            reviewerReward = spentReviewerRewardsOnIteration[iterationNumber];
            rewardReviewer(reviewerReward);
        }
        dealBudget = dealBudget.sub(contractorsReward).sub(platformReward).sub(reviewerReward);
    }

    function rewardContractor(uint256 amount) private {
        sendAssetsTo(contractor, amount, ERROR_REWARD_TRANSFER_FAILED);
    }

    function rewardPlatform(uint256 amount) private {
        sendAssetsTo(platform, amount, ERROR_REWARD_TRANSFER_FAILED);
    }

    function rewardReviewer(uint256 amount) private {
        sendAssetsTo(reviewer, amount, ERROR_REWARD_TRANSFER_FAILED);
    }

    function defineReviewerReward() private {
        mapping (uint32 => uint256) storage sRROI = spentReviewerRewardsOnIteration;
        sRROI[iterationNumber] = getPotentialReviewerReward();
    }

    function sendAssetsTo(address payable who, uint256 howMuch, string memory errorMsg) private {
        if (address(dealMeanOfPayment) == address(0)) {
            bool success = who.send(howMuch);
            require(success, errorMsg);
        } else {
            require(dealMeanOfPayment.transfer(who, howMuch), errorMsg);
        }
    }
}
