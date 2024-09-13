// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

interface IYT is IERC20Metadata {
    function SY() external view returns (address);

    function PT() external view returns (address);

    function factory() external view returns (address);

    function expiry() external view returns (uint256);

    function isExpired() external view returns (bool);

    function syReserve() external view returns (uint256);

    function stripSy(
        address receiver,
        uint256 amountSy
    ) external returns (uint256 amountPt, uint256 amountYt);

    function redeemSy(
        address receiver,
        uint256 amountPt
    ) external returns (uint256 amountSy);

    function redeemSyBeforeExpiry(
        address receiver,
        uint256 amountPt,
        uint256 amountYt
    ) external returns (uint256 amountSy);

    function redeemDueInterest(
        address user
    ) external returns (uint256 interestOut);

    // These 3 are non-view by intention
    function previewStripSy(
        uint256 amountSy
    ) external returns (uint256 amountPt, uint256 amountYt);

    function previewRedeemSy(
        uint256 amountPt
    ) external returns (uint256 amountSy);

    function previewRedeemSyBeforeExpiry(
        uint256 amountPt,
        uint256 amountYt
    ) external returns (uint256 amountSy);

    function currentSyExchangeRate()
        external
        returns (uint256 _currentSyExchangeRate);
}
