// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IYT} from "../interfaces/core/IYT.sol";
import {ISY} from "..//interfaces/core/ISY.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import {console} from "forge-std/console.sol";

contract YTRouter {
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
        address _msgSender = msg.sender;
        address self = address(this);

        // Tranfer Token In & Approve
        IERC20(tokenIn).transferFrom(_msgSender, self, amountToken);
        IERC20(tokenIn).approve(SY, amountToken);
        uint256 amountSy = ISY(SY).deposit(YT, tokenIn, amountToken, 0); // Need to check 0 later

        // amountSyIn is transferred to the YT contract before calling this function
        (amountPt, amountYt) = IYT(YT).stripSy(
            _msgSender,
            _msgSender,
            amountSy
        );
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
        address _msgSender = msg.sender;
        address self = address(this);

        IERC20(PT).transferFrom(_msgSender, YT, amountPt);

        // amountPt is transferred to the YT contract before calling this function
        uint256 amountSy = IYT(YT).redeemSy(self, amountPt);

        amountToken = ISY(SY).redeem(_msgSender, amountSy, tokenOut, 0, false);
    }

    /**
     *
     * @notice Please approve amountPt & amountYt to this contract before calling this function
     */
    function redeemBeforeExpiry(
        address SY,
        address PT,
        address YT,
        address tokenOut,
        uint256 amountPt,
        uint256 amountYt
    ) external returns (uint256 amountToken) {
        address _msgSender = msg.sender;
        address self = address(this);

        IERC20(PT).transferFrom(_msgSender, YT, amountPt);
        IERC20(YT).transferFrom(_msgSender, YT, amountYt);

        // amountPt & amountYt are transferred to the YT contract before calling this function
        uint256 amountSy = IYT(YT).redeemSyBeforeExpiry(
            self,
            amountPt,
            amountYt
        );

        amountToken = ISY(SY).redeem(_msgSender, amountSy, tokenOut, 0, false);
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
