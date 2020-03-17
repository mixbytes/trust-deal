pragma solidity 0.5.7;

import "../../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import './base.sol';

contract DealReviewStateLogic is BaseDealStateTransitioner {
    using SafeMath for uint32;
    using SafeMath for uint256;

    // TODO dirty
    function reviewOk() external {
        require(currentState == States.REVIEW, "Call from wrong state");
        require((msg.sender == reviewer &&
                reviewerDecisionTimeIntervalStart.add(reviewerDecisionDuration) > now
            ) || now >= reviewerDecisionTimeIntervalStart.add(reviewerDecisionDuration),
            "Actor can't make review decision"
        );

        uint256 platformFeeAmount = dealBudget.mul(platformFeeBPS).div(10000);
        uint256 reviewerFeeAmount = dealBudget.mul(reviewerFeeBPS).div(10000);

        if (address(dealToken) == address(0)) {
            // using ethers, not tokens
            address(uint160(contractor)).transfer(totalCosts); // TODO dev-note 13
            address(uint160(platform)).transfer(platformFeeAmount);

            if (reviewerDecisionTimeIntervalStart.add(reviewerDecisionDuration) > now) {
                address(uint160(reviewer)).transfer(reviewerFeeAmount);
            }
        } else {
            require(
                dealToken.transfer(contractor, totalCosts),
                "Contractor reward transfer failed"
            );

            if (reviewerDecisionTimeIntervalStart.add(reviewerDecisionDuration) > now) {
                require(
                    dealToken.transfer(reviewer, reviewerFeeAmount),
                    "Reviewer reward transfer failed"
                );
            }

            require(
                dealToken.transfer(platform, platformFeeAmount),
                "Platform reward transfer failed"
            );
        }

        totalCostsOnIteration[iterationNumber] = totalCosts;
        totalCosts = 0;
        currentState = States.WAIT4DEPOSIT;
    }

    function reviewFailed() external onlyReviewer {
        require(currentState == States.REVIEW, "Call from wrong state");

        uint256 platformFeeAmount = dealBudget.mul(platformFeeBPS).div(10000);
        uint256 reviewerFeeAmount = dealBudget.mul(reviewerFeeBPS).div(10000);

        if (address(dealToken) == address(0)) {
            address(uint160(contractor)).transfer(totalCosts); // TODO dev-note 13
            address(uint160(platform)).transfer(platformFeeAmount);
            address(uint160(reviewer)).transfer(reviewerFeeAmount);
            address(uint160(client)).transfer(address(this).balance);
        } else {
            require(
                dealToken.transfer(contractor, totalCosts),
                "Contractor reward transfer failed"
            );
            require(
                dealToken.transfer(platform, platformFeeAmount),
                "Platform reward transfer failed"
            );
            require(
                dealToken.transfer(reviewer, reviewerFeeAmount),
                "Reviewer reward transfer failed"
            );
            // will revert if `balanceOf` fails
            uint256 balanceOfDeal = dealToken.balanceOf(address(this));
            // TODO should we check balanceOfDeal gt 0??
            require(
                dealToken.transfer(msg.sender, balanceOfDeal),
                "Transfering client tokens on deal finish failed"
            );
        }

        currentState = States.END;
    }
}