// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IPtYtFactory {
    function createPtYt(
        address SY,
        uint256 expiry
    ) external returns (address PT, address YT);

    function setInterestFeeRate(uint256 newInterestFeeRate) external;

    function setTreasury(address newTreasury) external;

    function interestFeeRate() external view returns (uint256);

    function treasury() external view returns (address);

    function getPT(address SY, uint256 expiry) external view returns (address);

    function getYT(address SY, uint256 expiry) external view returns (address);

    function isPT(address token) external view returns (bool);

    function isYT(address token) external view returns (bool);

    function owner() external view returns (address);
}
