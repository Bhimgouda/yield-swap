// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IYT} from "../interfaces/core/IYT.sol";
import {ISY} from "..//interfaces/core/ISY.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract RouterYT {
    /**
     *
     * @notice Please approve amountToken to this contract before calling this function
     */
    function strip(
        address SY,
        address YT,
        address tokenIn,
        uint256 amountToken
    ) external returns (uint256 amountPt, uint256 amountYt) {
        address reciever = msg.sender;
        address self = address(this);

        // Tranfer Token In & Approve
        IERC20(tokenIn).transferFrom(reciever, self, amountToken);
        IERC20(tokenIn).approve(SY, amountToken);
        uint256 amountSy = ISY(SY).deposit(self, tokenIn, amountToken, 0); // Need to check 0 later

        IERC20(SY).approve(YT, amountSy);
        (amountPt, amountYt) = IYT(YT).stripSy(reciever, amountSy);
    }

    /**
     *
     * @notice Please approve amountPt to this contract before calling this function
     */
    function redeem(
        address SY,
        address PT,
        address YT,
        address tokenOut,
        uint256 amountPt
    ) external returns (uint256 amountToken) {
        address reciever = msg.sender;
        address self = address(this);

        IERC20(PT).transferFrom(reciever, self, amountPt);
        uint256 amountSy = IYT(YT).redeemSy(self, amountPt);

        amountToken = ISY(SY).redeem(reciever, amountSy, tokenOut, 0, false);
    }

    /**
     *
     * @notice Please approve amountPt to this contract before calling this function
     */
    function redeemBeforeExpiry(
        address SY,
        address PT,
        address YT,
        address tokenOut,
        uint256 amountPt,
        uint256 amountYt
    ) external returns (uint256 amountToken) {
        address reciever = msg.sender;
        address self = address(this);

        IERC20(PT).transferFrom(reciever, self, amountPt);
        IERC20(YT).transferFrom(reciever, self, amountYt);
        uint256 amountSy = IYT(YT).redeemSyBeforeExpiry(
            self,
            amountPt,
            amountYt
        );

        amountToken = ISY(SY).redeem(reciever, amountSy, tokenOut, 0, false);
    }

    function previewStrip(
        address SY,
        address YT,
        address tokenIn,
        uint256 amountToken
    ) external returns (uint256 amountPt, uint256 amountYt) {
        uint256 amountSy = ISY(SY).previewDeposit(tokenIn, amountToken);
        (amountPt, amountYt) = IYT(YT).previewStripSy(amountSy);
    }

    function previewRedeem(
        address SY,
        address YT,
        address tokenOut,
        uint256 amountPt
    ) external returns (uint256 amountToken) {
        uint256 amountSy = IYT(YT).previewRedeemSy(amountPt);
        amountToken = ISY(SY).previewRedeem(tokenOut, amountSy);
    }

    function previewRedeemBeforeExpiry(
        address SY,
        address YT,
        address tokenOut,
        uint256 amountPt,
        uint256 amountYt
    ) external returns (uint256 amountToken) {
        uint256 amountSy = IYT(YT).previewRedeemSyBeforeExpiry(
            amountPt,
            amountYt
        );
        amountToken = ISY(SY).previewRedeem(tokenOut, amountSy);
    }
}
