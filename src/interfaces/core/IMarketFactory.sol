// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IMarketFactory {
    function i_maxLnFeeRateRoot() external view returns (uint256);

    function MIN_INITIAL_ANCHOR() external view returns (uint256);

    function treasury() external view returns (address);

    function reserveFeePercent() external view returns (uint256);

    function createNewMarket(
        address PT,
        uint256 scalarRoot,
        uint256 initialAnchor,
        uint256 lnFeeRateRoot
    ) external returns (address market);

    function PtYtFactory() external view returns (address);
}
