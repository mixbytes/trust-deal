pragma solidity 0.5.7;

import './state_transitions/mainTransitioner.sol';
import './interfaces/IDealVersioning.sol';


contract TMIterativeDeal is MainDealStateTransitioner, IDealVersioning {
    // TODO ETH_TOKEN = address(0)
    constructor() public {
        client = msg.sender;
    }

    function getDealType() external pure returns (string memory) {
        return "TMIterativeDeal";
    }

    function getDealVersion() external pure returns (uint8, uint8, uint16) {
        Version memory v = Version(0, 0, 1);
        return (v.major, v.minor, v.patch);
    }
}