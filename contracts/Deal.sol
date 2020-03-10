pragma solidity 0.5.7;

import '../node_modules/openzeppelin-solidity/contracts/token/ERC20/IERC20.sol'; // tmp

contract DealDataRows {
    string taskDescription;

    address client;
    address contractor;
    address reviewer;

    IERC20 public dealToken;

    uint256 reviewerFee;

    uint64 iterationDuration;
    uint64 reviewerDecisionDuration; // TODO опасно ставить параметр конечная временная точка, тк надо будет проверять на каждом состоянии.
    uint64 reviewerDecisionTimeIntervalStart;
}

contract DealStateTransitioner is DealDataRows {
    enum States {INIT, PROPOSED_REVIEWER, RFP, DEPOSIT_WAIT, ITERATION}
    States public currentState;
}

contract Deal is DealStateTransitioner {
    constructor(string memory taskDescr_, uint64 iterationTimeout_, IERC20 dealToken_) public {
        client = msg.sender;

        taskDescription = taskDescr_;
        iterationDuration = iterationTimeout_;
        dealToken = dealToken_;
    }
}