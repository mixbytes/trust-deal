pragma solidity 0.5.7;

import './interfaces/ITMIterativeDealsRegistry.sol';

contract TMIterativeDealsRegistry is ITMIterativeDealsRegistry {
    mapping (address => ITMIterativeDeal[]) clientsDeals;
    mapping (address => ITMIterativeDeal[]) reviewersDeals;
    mapping (address => ITMIterativeDeal[]) employeesDeals;
    mapping (address => ITMIterativeDeal[]) contractorsDeals;

    function setDealForClient(address client, ITMIterativeDeal deal) external {
        clientsDeals[client].push(deal);
    }

    function getDealsOfClient(address client) external view returns (ITMIterativeDeal[] memory) {
        return clientsDeals[client];
    }

    function setDealForContractor(address contractor, ITMIterativeDeal deal) external {
        if (isNotRegisteredInDeal(contractorsDeals[contractor], deal)) {
            contractorsDeals[contractor].push(deal);
        }
    }

    function getDealsOfContractor(address contractor)
        external
        view
        returns (ITMIterativeDeal[] memory)
    {
        return contractorsDeals[contractor];
    }

    function setDealForReviewer(address reviewer, ITMIterativeDeal deal) external {
        reviewersDeals[reviewer].push(deal);
    }

    function getDealsOfReviewer(address reviewer)
        external
        view
        returns (ITMIterativeDeal[] memory)
    {
        return reviewersDeals[reviewer];
    }

    function setDealForEmployees(address[] calldata employees, ITMIterativeDeal deal) external {
        for (uint8 i; i < employees.length; i++) {
            address employee = employees[i];
            if (isNotRegisteredInDeal(employeesDeals[employee], deal)) {
                employeesDeals[employee].push(deal);
            }
        }
    }

    function getDealsOfEmployee(address employee)
        external
        view
        returns (ITMIterativeDeal[] memory)
    {
        return employeesDeals[employee];
    }

    function isNotRegisteredInDeal(ITMIterativeDeal[] memory actorsDeals, ITMIterativeDeal deal)
        internal
        pure
        returns (bool)
    {
        // TODO expensive, length is not controlled, stated in Tech prject
        for (uint16 i; i < actorsDeals.length; i++) {
            if (actorsDeals[i] == deal) return false;
        }

        return true;
    }
}