pragma solidity 0.5.7;

import './ITMIterativeDeal.sol';


/**
 * @dev Interface of a registry which lists deals for various roles.
 */
interface ITMIterativeDealsRegistry {

    /// @dev Lists deals of `client`.
    function getDealsOfClient(address client) external view returns (ITMIterativeDeal[] memory);

    /// @dev Lists deals of `contractor`.
    function getDealsOfContractor(address contractor) external view returns (ITMIterativeDeal[] memory);

    /// @dev Lists deals of `reviewer`.
    /// Note: result should include deals in `PROPOSED_REVIEWER` state.
    function getDealsOfReviewer(address reviewer) external view returns (ITMIterativeDeal[] memory);

    /// @dev Lists deals which list `employee` in the workforce.
    function getDealsOfEmployee(address employee) external view returns (ITMIterativeDeal[] memory);

    /// @notice Setters called by TMIterativeDeal

    /// @dev Called to map client to deal
    function setDealForClient(address client, ITMIterativeDeal deal) external;

    /// @dev Called to map contractor to deal
    function setDealForContractor(address contractor, ITMIterativeDeal deal) external;

    /// @dev Called to map reviewer to deal
    function setDealForReviewer(address reviewer, ITMIterativeDeal deal) external;

    /// @dev Called to map employees to deal
    function setDealForEmployees(address[] calldata employees, ITMIterativeDeal deal) external;
}
