pragma solidity 0.5.7;

import './state-transitions/mainTransitioner.sol';
import './interfaces/IDealVersioning.sol';


contract TMIterativeDeal is MainDealStateTransitioner, IDealVersioning {
    // TODO ETH_TOKEN = address(0)
    constructor() public {
        client = msg.sender;
    }

    function getClient() external view returns (address) {
        return client;
    }

    function getDealType() external pure returns (string memory) {
        return "TMIterativeDeal";
    }

    function getDealVersion() external pure returns (uint8, uint8, uint16) {
        Version memory v = Version(0,0,1);
        return (v.major, v.minor, v.patch);
    }

    function getInfo() external view returns (
        States state,
        address client,
        string memory shortName,
        string memory task,
        uint32 iterationTimeSeconds,
        IERC20 paymentToken,
        address dealReviewer,
        uint16 feeBPS,
        uint32 reviewTimeoutSeconds
    ) {
        return (
            currentState,
            client,
            taskShortName,
            taskDescription,
            iterationDuration,
            dealToken,
            reviewer,
            reviewerFeeBPS,
            reviewerDecisionDuration
        );
    }
}