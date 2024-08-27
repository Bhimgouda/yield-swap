// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IPtYtFactory {
    function createPtYt(
        address sy,
        uint256 expiry
    ) external returns (address pt, address yt);

    function setInterestFeeRate(uint256 newInterestFeeRate) external;

    function setTreasury(address newTreasury) external;

    function _generatePtYtMetadata(
        address sy
    )
        external
        view
        returns (
            string memory ptName,
            string memory ptSymbol,
            string memory ytName,
            string memory ytSymbol
        );

    function _getSyMetadata(
        address sy
    ) external view returns (string memory name, string memory symbol);

    function interestFeeRate() external view returns (uint256);
}
