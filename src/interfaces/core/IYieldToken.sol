// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.24;

import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

interface IYieldToken is IERC20Metadata {
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

    function previewStripSy(
        uint256 amountSy
    ) external view returns (uint256 amountPt, uint256 amountYt);

    function previewRedeemSy(
        uint256 amountPt
    ) external view returns (uint256 amountSy);

    function getSY() external view returns (address);

    function getPT() external view returns (address);

    function getExpiry() external view returns (uint256);
}
