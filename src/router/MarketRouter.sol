// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IYT} from "../interfaces/core/IYT.sol";
import {ISY} from "../interfaces/core/ISY.sol";
import {Market} from "../core/Market/Market.sol";
import {MarketMath, MarketState, PMath} from "../core/Market/MarketMath.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import {MarketApproxLib} from "./MarketApproxLib.sol";
import {MarketCallback} from "./MarketCallback.sol";

import {console} from "forge-std/console.sol";

contract MarketRouter is MarketCallback {
    using MarketMath for MarketState;
    using PMath for uint256;
    using MarketApproxLib for MarketState;

    bytes internal constant EMPTY_BYTES = abi.encode();

    function addLiquidity(
        address SY,
        address ybtIn,
        address market,
        uint256 amountYbtIn,
        uint256 amountPtIn
    ) external returns (uint256 lpOut) {
        address self = address(this);
        address _msgSender = msg.sender;
        address PT = address(Market(market).PT());

        IERC20(PT).transferFrom(_msgSender, market, amountPtIn);
        IERC20(ybtIn).transferFrom(_msgSender, self, amountYbtIn);

        IERC20(ybtIn).approve(SY, amountYbtIn);
        uint256 amountSyIn = ISY(SY).deposit(market, ybtIn, amountYbtIn, 0);

        (lpOut, , ) = Market(market).addLiquidity(
            _msgSender,
            amountSyIn,
            amountPtIn
        );
    }

    function removeLiquidity(
        address SY,
        address ybtOut,
        address market,
        uint256 lpToRemove
    ) external returns (uint256 amountYbtOut, uint256 amountPtOut) {
        address self = address(this);
        address _msgSender = msg.sender;

        // Transeferring LP Tokens to market
        IERC20(market).transferFrom(_msgSender, market, lpToRemove);

        uint256 amountSyOut;
        (amountSyOut, amountPtOut) = Market(market).removeLiquidity(
            self,
            _msgSender,
            lpToRemove
        );

        IERC20(SY).approve(SY, amountSyOut);
        amountYbtOut = ISY(SY).redeem(
            _msgSender,
            amountSyOut,
            ybtOut,
            0,
            false
        );
    }

    /**
     * @notice Uses approx swap
     */
    function swapExactYbtForPt(
        address SY,
        address ybtIn,
        address market,
        uint256 amountYbtIn
    ) external returns (uint256 amountPtOut) {
        address _msgSender = msg.sender;
        address self = address(this);

        // Ybt to Sy
        IERC20(ybtIn).transferFrom(_msgSender, self, amountYbtIn);
        IERC20(ybtIn).approve(SY, amountYbtIn);
        uint256 amountSyIn = ISY(SY).deposit(market, ybtIn, amountYbtIn, 0);

        amountPtOut = _getApproxPtOutForExactSyIn(market, amountSyIn);

        // amountSyIn is transferred to the market contract before calling this function
        Market(market).swapSyForExactPt(_msgSender, amountPtOut, EMPTY_BYTES);
    }

    function swapExactPtForYbt(
        address SY,
        address ybtOut,
        address market,
        uint256 amountPtIn
    ) external returns (uint256 amountYbtOut) {
        address _msgSender = msg.sender;
        address self = address(this);

        address PT = address(Market(market).PT());
        IERC20(PT).transferFrom(_msgSender, market, amountPtIn);

        // amountPtIn is transferred to the market contract before calling this function
        (uint256 amountSyOut, ) = Market(market).swapExactPtForSy(
            self,
            amountPtIn,
            EMPTY_BYTES
        );

        amountYbtOut = ISY(SY).redeem(
            _msgSender,
            amountSyOut,
            ybtOut,
            0,
            false
        );
    }

    /**
     * @notice Uses approx swap
     */
    function swapExactYbtForYt(
        address SY,
        address ybtIn,
        address market,
        uint256 amountYbtIn
    ) external returns (uint256 amountYtOut) {
        address _msgSender = msg.sender;
        address self = address(this);
        address YT = address(Market(market).YT());

        // ybt to sy
        IERC20(ybtIn).transferFrom(_msgSender, self, amountYbtIn);
        IERC20(ybtIn).approve(SY, amountYbtIn);
        uint256 amountSyIn = ISY(SY).deposit(YT, ybtIn, amountYbtIn, 0); // Need to check 0 later 0)

        amountYtOut = _getApproxYtOutForExactSyIn(market, amountSyIn);

        // Flashswap SY
        (, uint256 amountSyFee) = Market(market).swapExactPtForSy(
            address(YT),
            amountYtOut,
            _encodeSwapExactSyForYt(_msgSender, YT, amountSyIn)
        );
    }

    function swapExactYtForYbt(
        address SY,
        address ybtOut,
        address market,
        uint256 amountYtIn
    ) external returns (uint256 amountYbtOut) {
        address _msgSender = msg.sender;
        address YT = address(Market(market).YT());

        uint256 preSyBalance = IERC20(SY).balanceOf(_msgSender);

        IERC20(YT).transferFrom(_msgSender, YT, amountYtIn);
        // Flashswap PT
        (, uint256 amountSyFee) = Market(market).swapSyForExactPt(
            YT,
            amountYtIn,
            _encodeSwapYtForSy(_msgSender, YT)
        );

        uint256 postSyBalance = IERC20(SY).balanceOf(_msgSender);

        uint256 amountSyOut = postSyBalance - preSyBalance;
        amountYbtOut = ISY(SY).previewRedeem(ybtOut, amountSyOut);
    }

    ///////////////////////////
    // READ
    /////////////////////////

    /**
     * @notice This is in terms of syDesired / amountSyIn
     */
    function previewAddLiquidity(
        address SY,
        address ybtIn,
        address market,
        uint256 amountYbtIn
    ) external view returns (uint256 amountPtUsed, uint256 amountLpOut) {
        MarketState memory marketState = Market(market).readState();

        uint256 amountSyIn = ISY(SY).previewDeposit(ybtIn, amountYbtIn);
        uint256 amountPtIn = 1000000000e18; //  Some Random Big Number

        uint256 amountSyUsed;
        (amountSyUsed, amountPtUsed, amountLpOut) = marketState.addLiquidity(
            amountSyIn,
            amountPtIn
        );
        require(amountSyUsed == amountSyIn);
    }

    function previewRemoveLiquidity(
        address SY,
        address ybtOut,
        address market,
        uint256 lpToRemove
    ) external view returns (uint256 amountYbtOut, uint256 amountPtOut) {
        MarketState memory marketState = Market(market).readState();

        uint256 amountSyOut;
        (amountSyOut, amountPtOut) = marketState.removeLiquidity(lpToRemove);

        amountYbtOut = ISY(SY).previewRedeem(ybtOut, amountSyOut);
    }

    function previewSwapExactYbtForPt(
        address SY,
        address ybtIn,
        address market,
        uint256 amountYbtIn
    ) public returns (uint256 amountPtOut) {
        uint256 amountSyIn = ISY(SY).previewDeposit(ybtIn, amountYbtIn);
        amountPtOut = _getApproxPtOutForExactSyIn(market, amountSyIn);
    }

    function previewSwapExactPtForYbt(
        address SY,
        address ybtOut,
        address market,
        uint256 amountPtIn
    ) external returns (uint256 amountYbtOut) {
        MarketState memory marketState = Market(market).readState();
        uint256 currentSyExchangeRate = Market(market).currentSyExchangeRate();

        (uint256 amountSyOut, , , ) = marketState.swapExactPtForSy(
            amountPtIn,
            currentSyExchangeRate
        );

        amountYbtOut = ISY(SY).previewRedeem(ybtOut, amountSyOut);
    }

    function previewSwapExactYbtForYt(
        address SY,
        address ybtIn,
        address market,
        uint256 amountYbtIn
    ) public returns (uint256 amountYtOut) {
        uint256 amountSyIn = ISY(SY).previewDeposit(ybtIn, amountYbtIn);
        amountYtOut = _getApproxYtOutForExactSyIn(market, amountSyIn);
    }

    function previewSwapExactYtForYbt(
        address SY,
        address ybtOut,
        address market,
        uint256 amountYtIn
    ) external returns (uint256 amountYbtOut) {
        address YT = address(Market(market).YT());
        MarketState memory marketState = Market(market).readState();
        uint256 currentSyExchangeRate = Market(market).currentSyExchangeRate();

        (uint256 amountSy, uint256 amountSyFee, , ) = marketState
            .swapSyForExactPt(amountYtIn, currentSyExchangeRate);
        uint256 amountSyToRepay = amountSy + amountSyFee;

        uint256 amountSyRedeemed = IYT(YT).previewRedeemSyBeforeExpiry(
            amountYtIn,
            amountYtIn
        );

        uint256 amountSyOut = amountSyRedeemed - amountSyToRepay;
        amountYbtOut = ISY(SY).previewRedeem(ybtOut, amountSyOut);
    }

    //////////////////////
    // Internal
    ///////////////////////

    function _getApproxPtOutForExactSyIn(
        address market,
        uint256 amountSyIn
    ) internal returns (uint256 amountPtOut) {
        MarketState memory marketState = Market(market).readState();
        uint256 currentSyExchangeRate = Market(market).currentSyExchangeRate();

        (amountPtOut, ) = marketState.approxSwapExactSyForPt(
            currentSyExchangeRate,
            amountSyIn
        );
    }

    function _getApproxYtOutForExactSyIn(
        address market,
        uint256 amountSyIn
    ) internal returns (uint256 amountYtOut) {
        MarketState memory marketState = Market(market).readState();
        uint256 currentSyExchangeRate = Market(market).currentSyExchangeRate();

        (amountYtOut, ) = marketState.approxSwapExactSyForYt(
            currentSyExchangeRate,
            amountSyIn
        );
    }
}
