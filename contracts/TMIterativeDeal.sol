pragma solidity 0.5.7;

import './state_transitions/mainTransitioner.sol';
import './interfaces/IDealVersioning.sol';

contract TMIterativeDeal is MainDealStateTransitioner, IDealVersioning {
    constructor(
        address payable platformAddress,
        uint16 platformFeeInBIPS,
        ITMIterativeDealsRegistry dealsRegistry
    )
        public
    {
        require(platformAddress != address(0), ERROR_ZERO_ADDRESS);
        require(
            platformFeeInBIPS > 0 && platformFeeInBIPS < 10000,
            "platform fee BPS could be only in range (0, 10000)"
        );
        client = msg.sender;
        platform = platformAddress;
        platformFeeBPS = platformFeeInBIPS;
        registry = dealsRegistry;
    }

    function getDealType() external pure returns (string memory) {
        return "TMIterativeDeal";
    }

    function getDealVersion() external pure returns (uint8, uint8, uint16) {
        Version memory v = Version(0, 0, 1);
        return (v.major, v.minor, v.patch);
    }
}