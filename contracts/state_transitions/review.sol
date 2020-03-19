pragma solidity 0.5.7;

import "../../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import '../../node_modules/openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol';

import './base.sol';
import './dealAssetPayer.sol';
import '../utils/Uint256Caster.sol';

contract DealReviewStateLogic is BaseDealStateTransitioner,
    DealPaymentsManager,
    ReentrancyGuard
{
    using Uint256Caster for uint256;
    using SafeMath for uint32;
    using SafeMath for uint256;

    event DealTaskReviewedPositively(uint32 when);

    function reviewOk() external nonReentrant {
        require(currentState == States.REVIEW, ERROR_WRONG_STATE_CALL);
        uint32 reviewDeadline = uint32(
            reviewerDecisionTimeIntervalStart.add(reviewerDecisionDuration)
        );
        require(
            (msg.sender == reviewer && reviewDeadline > now) || now >= reviewDeadline,
            "Actor can't make review decision"
        );

        (uint256 platformReward, uint256 reviewerReward) = calculatePlatformReviewerRewards();
        bool shouldPayReviewer = reviewDeadline > now;

        rewardActors(shouldPayReviewer, platformReward, reviewerReward);

        dealBudget = dealBudget.sub(contractorsReward).sub(platformReward).sub(reviewerReward);
        contractorsReward = 0;
        currentState = States.WAIT4DEPOSIT;
        emit DealTaskReviewedPositively(now.toUint32());
    }

    function reviewFailed() external onlyReviewer nonReentrant {
        require(currentState == States.REVIEW, ERROR_WRONG_STATE_CALL);

        (uint256 platformReward, uint256 reviewerReward) = calculatePlatformReviewerRewards();

        rewardActors(true, platformReward, reviewerReward);
        payRestToClient();

        currentState = States.END;
        emit DealEndedUp(States.REVIEW);
    }

    function calculatePlatformReviewerRewards() internal view returns (uint256, uint256) {
        uint256 platformFeeAmount = dealBudget.mul(platformFeeBPS).div(10000);
        uint256 reviewerFeeAmount = dealBudget.mul(reviewerFeeBPS).div(10000);
        return (platformFeeAmount, reviewerFeeAmount);
    }
}