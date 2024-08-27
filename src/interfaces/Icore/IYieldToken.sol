// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.24;

interface IYieldToken {
    function stripSy(
        address receiver,
        uint256 amountSy
    ) external returns (uint256 amountPt, uint256 amountYt);

    function redeemSy(
        address receiver,
        uint256 amountPt,
        uint256 amountYt
    ) external returns (uint256 amountSy);

    function redeemSyByPt(uint256 amountPt) external returns (uint256 amountSy);

    function previewStrip(
        uint256 amountSy
    ) external view returns (uint256 amountPt, uint256 amountYt);

    function previewRedeemSyByPt(
        uint256 amountPt
    ) external view returns (uint256 amountSy);
}
