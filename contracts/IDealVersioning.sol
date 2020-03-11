pragma solidity 0.5.7;


/**
 * @dev Getting version information from a deal.
 */
interface IDealVersioning {

    /// @dev returns the type name of the deal, e.g. TMIterativeDeal
    function getDealType() external pure returns (string memory);

    /// @dev returns semver of the deal, e.g. [1, 5, 200]
    function getDealVersion() external pure returns (uint16[] memory);
}
