// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {PMath} from "../libraries/math/PMath.sol";
import {LogExpMath} from "../libraries/math/LogExpMath.sol";

import {console} from "forge-std/console.sol";

/**
 * @notice This is to find the price of Asset in terms of PT, using notional AMM
 */

struct MarketState {
    uint256 totalSy;
    uint256 totalPt;
    uint256 totalLp;
    uint256 lastLnImpliedRate;
    /// immutable variables ///
    int256 scalarRoot;
    uint256 expiry;
    uint256 lnFeeRateRoot;
}

contract MarketMath {
    using PMath for uint256;
    using PMath for int256;
    using LogExpMath for int256;

    uint256 public constant DAY = 86400;
    uint256 public constant YEAR = 365 * DAY;

    function addLiquidity(
        MarketState memory market,
        uint256 syDesired,
        uint256 ptDesired
    ) public pure returns (uint256 lpOut, uint256 syUsed, uint256 ptUsed) {
        require(
            syDesired != 0 && ptDesired != 0,
            "syDesired or ptDesired cannot be 0"
        );

        // Need to Revert if Market is expired
        // if this function also gets called by the router contracts in future

        if (market.totalLp == 0) {
            // Using uniswap's sqrt(amount0 * amount1) for calculating initial LP
            lpOut = PMath.sqrt(syDesired * ptDesired);

            syUsed = syDesired;
            ptUsed = ptDesired;
        } else {
            /// ------------------------------------------------------------
            /// MATH
            /// ------------------------------------------------------------

            // Formula used (Propotionality change formula - Ratio of change should be equal)
            // (x + dx) / x = (y + dy) / y
            // dy = (dx * y) / x

            uint256 lpAmountBySy = (syDesired * market.totalLp) /
                market.totalSy;
            uint256 lpAmountByPt = (ptDesired * market.totalLp) /
                market.totalPt;

            // Minimum LP is minted, as desiredPt or Sy should not be exceeded
            if (lpAmountBySy < lpAmountByPt) {
                syUsed = syDesired;
                lpOut = lpAmountBySy;

                // Now finding corresponding pt from lp using, dy = (dx * y) / x
                ptUsed = (lpOut * market.totalPt) / market.totalLp;
            } else {
                ptUsed = ptDesired;
                lpOut = lpAmountByPt;

                // Now finding corresponding sy from lp using, dy = (dx * y) / x
                syUsed = (lpOut * market.totalSy) / market.totalLp;
            }
        }
    }

    function removeLiquidity(
        MarketState memory market,
        uint256 lpAmount
    ) public pure returns (uint256 syOut, uint256 ptOut) {
        require(lpAmount != 0, "Lp to remove cannot be 0");

        /// ------------------------------------------------------------
        /// MATH
        /// ------------------------------------------------------------

        // Formula used (Propotionality change formula - Ratio of change should be equal)
        // (x - dx) / x = (y - dy) / y
        // dy = (dx * y) / x

        syOut = (lpAmount * market.totalSy) / market.totalLp;
        ptOut = (lpAmount * market.totalPt) / market.totalLp;
    }

    function swapSyForExactPt(
        MarketState memory market,
        uint256 amountPtOut,
        uint256 currentSyExchangeRate,
        uint256 timeToExpiry
    )
        public
        pure
        returns (
            uint256 amountSyIn,
            uint256 amountSyFee,
            uint256 updatedLnImpliedRate
        )
    {
        (amountSyIn, amountSyFee, updatedLnImpliedRate) = swapCore(
            market,
            amountPtOut.Int(),
            currentSyExchangeRate,
            timeToExpiry
        );
    }

    function swapExactPtForSy(
        MarketState memory market,
        uint256 amountPtIn,
        uint256 currentSyExchangeRate,
        uint256 timeToExpiry
    )
        public
        pure
        returns (
            uint256 amountSyOut,
            uint256 amountSyFee,
            uint256 updatedLnImpliedRate
        )
    {
        (amountSyOut, amountSyFee, updatedLnImpliedRate) = swapCore(
            market,
            amountPtIn.neg(),
            currentSyExchangeRate,
            timeToExpiry
        );
    }

    function swapCore(
        MarketState memory market,
        int256 amountPtChange,
        uint256 currentSyExchangeRate,
        uint256 timeToExpiry
    )
        public
        pure
        returns (
            uint256 amountSyChange,
            uint256 amountSyFee,
            uint256 updatedLnImpliedRate
        )
    {
        // Get Required Variables
        int256 totalAsset = (market.totalSy.mulDown(currentSyExchangeRate))
            .Int();
        int256 totalPt = market.totalPt.Int();

        require(market.totalPt > 0 && totalAsset > 0, "Zero Pt or Asset");
        require(amountPtChange < totalPt, "Amount Pt Change too high");

        int256 rateScalar = _getRateScalar(market.scalarRoot, timeToExpiry);
        int256 rateAnchor = _getRateAnchor(
            market.lastLnImpliedRate,
            totalAsset,
            totalPt,
            rateScalar,
            timeToExpiry
        );

        // Calc exchange rate
        int256 exchangeRate = _getExchangeRate(
            totalAsset,
            totalPt,
            rateScalar,
            rateAnchor,
            amountPtChange
        );

        int256 amountAsset = amountPtChange.divDown(exchangeRate);

        updatedLnImpliedRate = _getLnImpliedRate(
            totalAsset + amountAsset,
            totalPt.subNoNeg(amountPtChange),
            rateScalar,
            rateAnchor,
            timeToExpiry
        );

        console.log("updatedLnImpliedRate", updatedLnImpliedRate);

        if (amountAsset < 0) {
            amountSyChange = (amountAsset.neg().Uint()).divDown(
                currentSyExchangeRate
            );
        } else {
            amountSyChange = (
                amountAsset.Uint().divDown(currentSyExchangeRate)
            );
        }
    }

    function setInitialLnImpliedRate(
        int256 scalarRoot,
        int256 initialAnchor,
        uint256 totalSy,
        uint256 totalPt,
        uint256 currentSyExchangeRate,
        uint256 timeToExpiry
    ) public pure returns (uint256 lastLnImpliedRate) {
        // SY held by pool in terms of ybt's Accounting/Underlying Asset
        int256 totalAsset = totalSy.mulDown(currentSyExchangeRate).Int();

        // Getting Rate scalar
        int256 rateScalar = _getRateScalar(scalarRoot, timeToExpiry);

        lastLnImpliedRate = _getLnImpliedRate(
            totalAsset,
            totalPt.Int(),
            rateScalar,
            initialAnchor,
            timeToExpiry
        );
    }

    /// ------------------------------------------------------------
    /// UTILITY FUNCTIONS
    /// ------------------------------------------------------------

    // Formula used, rateScalar = i_scalarRoot / years to expiry
    // where, years to expiry  = timeToExpiry / 365(1 Year)
    function _getRateScalar(
        int256 scalarRoot,
        uint256 timeToExpiry
    ) public pure returns (int256 rateScalar) {
        rateScalar = (scalarRoot * YEAR.Int()) / timeToExpiry.Int();

        require(rateScalar > 0, "Invalid rate scalar");
    }

    // Formula used, exchangeRate(t*) = lastImpliedRate^yearsToExpiry (Pre-trade)
    function _getNextExchangeRateFromLastLnImpliedRate(
        uint256 lastLnImpliedRate,
        uint256 timeToExpiry
    ) public pure returns (int256 nextExhangeRate) {
        return
            LogExpMath.exp(((lastLnImpliedRate * timeToExpiry) / YEAR).Int());
    }

    function _getRateAnchor(
        uint256 lastLnImpliedRate,
        int256 totalAsset,
        int256 totalPt,
        int256 rateScalar,
        uint256 timeToExpiry
    ) public pure returns (int256 rateAnchor) {
        int256 nextExhangeRate = _getNextExchangeRateFromLastLnImpliedRate(
            lastLnImpliedRate,
            timeToExpiry
        );

        require(nextExhangeRate >= PMath.IONE, "Exchange rate below 1");

        int256 lastProportion = totalPt.divDown(totalPt + totalAsset);

        int256 lastExchangeRate = LogExpMath
            .ln(lastProportion.divDown(PMath.IONE - lastProportion))
            .divDown(rateScalar);

        rateAnchor = nextExhangeRate - lastExchangeRate;
    }

    function _getExchangeRate(
        int256 totalAsset,
        int256 totalPt,
        int256 rateScalar,
        int256 rateAnchor,
        int256 amountPtChange
    ) public pure returns (int256 exchangeRate) {
        // X = asset, Y = PT, (pt - (+dpt)) for BUY, (pt - (-dpt)) for SELL
        // Formula used, proportion = (y - (dpt)) / x + y,
        int256 proportion = totalPt.subNoNeg(amountPtChange).divDown(
            totalAsset + totalPt
        );

        // Formula used, assetPrice = (ln(p / 1-p) / rateScalar) + anchorRate
        exchangeRate =
            LogExpMath.ln(proportion.divDown(PMath.IONE - proportion)).divDown(
                rateScalar
            ) +
            rateAnchor;

        // As assetPrice is always more that PT price before expiry, and 1 at expiry
        require(exchangeRate >= PMath.IONE, "Invalid exchange rate");
    }

    // Formula used, (ln(exchangeRate) * year) / timeToExpiry (Post-trade)
    function _getLnImpliedRate(
        int256 totalAsset,
        int256 totalPt,
        int256 rateScalar,
        int256 rateAnchor,
        uint256 timeToExpiry
    ) public pure returns (uint256 lnImpliedRate) {
        console.log("OtotalAsset", totalAsset);
        // console.log("OtotalPt", totalPt);

        int256 exchangeRate = _getExchangeRate(
            totalAsset,
            totalPt,
            rateScalar,
            rateAnchor,
            0
        );

        lnImpliedRate =
            (LogExpMath.ln(exchangeRate).Uint() * YEAR) /
            timeToExpiry;
    }
}
