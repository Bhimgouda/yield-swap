// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IPtYtFactory {
    /*///////////////////////////////////////////////////////////////
                            Events
    //////////////////////////////////////////////////////////////*/
    event PtYtCreated(address indexed pt, address indexed yt, address indexed sy, uint256 expiry);
    event InterestFeeRateUpdated(uint256 oldRate, uint256 newRate);
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);

    /*///////////////////////////////////////////////////////////////
                            Functions
    //////////////////////////////////////////////////////////////*/
    function createPtYt(address sy, uint256 expiry) external returns (address pt, address yt);

    function setInterestFeeRate(uint256 newInterestFeeRate) external;

    function setTreasury(address newTreasury) external;

    /*///////////////////////////////////////////////////////////////
                            View Functions
    //////////////////////////////////////////////////////////////*/
    function getInterestFeeRate() external view returns (uint256);

    function getTreasury() external view returns (address);

    function owner() external view returns (address);
}
