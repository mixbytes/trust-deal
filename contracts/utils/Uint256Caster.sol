pragma solidity 0.5.7;

// copy from https://github.com/aragon/aragonOS/blob/v4.2.0/contracts/common/Uint256Helpers.sol

library Uint256Caster {
    uint256 private constant MAX_UINT32 = uint32(-1);

    function toUint32(uint256 a) internal pure returns (uint32) {
        require(a <= MAX_UINT32, "Too big to cast to uint32");
        return uint32(a);
    }
}