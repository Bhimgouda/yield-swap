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
    uint256 timeToExpiry; // 0 if the market is expired
    /// immutables ///
    uint256 scalarRoot;
    uint256 lnFeeRateRoot;
    uint256 reserveFeePercent; // base 100
}

// params that are expensive to compute, therefore we pre-compute them
struct MarketPreCompute {
    int256 rateScalar;
    int256 totalAsset;
    int256 rateAnchor;
    int256 feeRate;
}

library MarketMath {
    using PMath for uint256;
    using PMath for int256;
    using LogExpMath for int256;

    uint256 public constant DAY = 86400;
    uint256 public constant YEAR = 365 * DAY;
    int256 public constant MAX_MARKET_PROPORTION = (1e18 * 96) / 100;
    int256 public constant PERCENTAGE_DECIMALS = 100;

    function addLiquidity(
        MarketState memory market,
        uint256 syDesired,
        uint256 ptDesired
    ) public pure returns (uint256 lpOut, uint256 syUsed, uint256 ptUsed) {
        require(
            syDesired > 0 && ptDesired > 0,
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
        uint256 lpToRemove
    ) public pure returns (uint256 syOut, uint256 ptOut) {
        require(lpToRemove != 0, "Lp to remove cannot be 0");

        /// ------------------------------------------------------------
        /// MATH
        /// ------------------------------------------------------------

        // Formula used (Propotionality change formula - Ratio of change should be equal)
        // (x - dx) / x = (y - dy) / y
        // dy = (dx * y) / x

        syOut = (lpToRemove * market.totalSy) / market.totalLp;
        ptOut = (lpToRemove * market.totalPt) / market.totalLp;
    }

    function swapSyForExactPt(
        MarketState memory market,
        uint256 amountPtOut,
        uint256 currentSyExchangeRate
    )
        public
        pure
        returns (
            uint256 amountSyIn,
            uint256 amountSyFee,
            uint256 amountSyToReserve,
            uint256 updatedLnImpliedRate
        )
    {
        (
            amountSyIn,
            amountSyFee,
            amountSyToReserve,
            updatedLnImpliedRate
        ) = swapCore(market, amountPtOut.Int(), currentSyExchangeRate);
    }

    function swapExactPtForSy(
        MarketState memory market,
        uint256 amountPtIn,
        uint256 currentSyExchangeRate
    )
        public
        pure
        returns (
            uint256 amountSyOut,
            uint256 amountSyFee,
            uint256 amountSyToReserve,
            uint256 updatedLnImpliedRate
        )
    {
        (
            amountSyOut,
            amountSyFee,
            amountSyToReserve,
            updatedLnImpliedRate
        ) = swapCore(market, amountPtIn.neg(), currentSyExchangeRate);
    }

    function swapCore(
        MarketState memory market,
        int256 amountPtChange,
        uint256 currentSyExchangeRate
    )
        public
        pure
        returns (
            uint256 amountSyChange,
            uint256 amountSyFee,
            uint256 amountSyToReserve,
            uint256 updatedLnImpliedRate
        )
    {
        require(
            amountPtChange < market.totalPt.Int(),
            "Amount Pt Change too high"
        );

        MarketPreCompute memory preComp = getMarketPreCompute(
            market,
            currentSyExchangeRate
        );

        (
            amountSyChange,
            amountSyFee,
            amountSyToReserve,
            updatedLnImpliedRate
        ) = calcSwap(market, preComp, amountPtChange, currentSyExchangeRate);
    }

    function getMarketPreCompute(
        MarketState memory market,
        uint256 currentSyExchangeRate
    ) public pure returns (MarketPreCompute memory res) {
        res.totalAsset = (market.totalSy.mulDown(currentSyExchangeRate)).Int();

        require(market.totalPt > 0 && res.totalAsset > 0, "Zero Pt or Asset");

        res.rateScalar = _getRateScalar(market.scalarRoot, market.timeToExpiry)
            .Int();

        res.rateAnchor = _getRateAnchor(
            market.lastLnImpliedRate,
            res.totalAsset,
            market.totalPt.Int(),
            res.rateScalar,
            market.timeToExpiry
        );

        res.feeRate = _getNextExchangeRateFromLastLnImpliedRate(
            market.lnFeeRateRoot,
            market.timeToExpiry
        );
    }

    function calcSwap(
        MarketState memory market,
        MarketPreCompute memory preComp,
        int256 amountPtChange,
        uint256 currentSyExchangeRate
    )
        public
        pure
        returns (
            uint256 amountSyChange,
            uint256 amountSyFee,
            uint256 amountSyToReserve,
            uint256 updatedLnImpliedRate
        )
    {
        int256 totalPt = market.totalPt.Int();
        int256 exchangeRate = _getExchangeRate(
            preComp.totalAsset,
            totalPt,
            preComp.rateScalar,
            preComp.rateAnchor,
            amountPtChange
        );

        int256 amountAsset = amountPtChange.divDown(exchangeRate).neg();

        int256 fee = preComp.feeRate;
        if (amountPtChange > 0) {
            int256 postFeeExchangeRate = exchangeRate.divDown(fee);
            require(
                postFeeExchangeRate > PMath.IONE,
                "Market Exchange Rate below 1"
            );

            fee = amountAsset.mulDown(PMath.IONE - fee);
        } else {
            fee = ((amountAsset * (PMath.IONE - fee)) / fee).neg();
        }

        int256 amountAssetToReserve = (fee * market.reserveFeePercent.Int()) /
            PERCENTAGE_DECIMALS;
        int256 amountAssetToAccount = amountAsset - fee;

        amountSyChange = (amountAssetToAccount.abs()).divDown(
            currentSyExchangeRate
        );
        amountSyFee = fee.Uint().divDown(currentSyExchangeRate);
        amountSyToReserve = amountAssetToReserve.Uint().divDown(
            currentSyExchangeRate
        );

        updatedLnImpliedRate = getPostTradeLnImpliedRate(
            market,
            preComp,
            amountPtChange,
            amountAssetToAccount,
            amountAssetToReserve
        );
    }

    function getPostTradeLnImpliedRate(
        MarketState memory market,
        MarketPreCompute memory preComp,
        int256 amountPtChange,
        int256 amountAssetToAccount,
        int256 amountAssetToReserve
    ) public pure returns (uint256 updatedLnImpliedRate) {
        int256 totalPt = market.totalPt.Int();

        updatedLnImpliedRate = _getLnImpliedRate(
            preComp.totalAsset.subNoNeg(
                amountAssetToAccount + amountAssetToReserve
            ),
            totalPt.subNoNeg(amountPtChange),
            preComp.rateScalar,
            preComp.rateAnchor,
            market.timeToExpiry
        );
    }

    function setInitialLnImpliedRate(
        MarketState memory market,
        uint256 initialAnchor,
        uint256 totalSy, // As marketState is not updated, we need to pass totalSy and totalPt at first addLiquidity
        uint256 totalPt,
        uint256 currentSyExchangeRate
    ) public pure returns (uint256 lastLnImpliedRate) {
        uint256 totalAsset = totalSy.mulDown(currentSyExchangeRate);
        uint256 rateScalar = _getRateScalar(
            market.scalarRoot,
            market.timeToExpiry
        );

        lastLnImpliedRate = _getLnImpliedRate(
            totalAsset.Int(),
            totalPt.Int(),
            rateScalar.Int(),
            initialAnchor.Int(),
            market.timeToExpiry
        );
    }

    /// ------------------------------------------------------------
    /// UTILITY FUNCTIONS
    /// ------------------------------------------------------------

    // Formula used, rateScalar = i_scalarRoot / years to expiry
    // where, years to expiry  = timeToExpiry / 365(1 Year)
    function _getRateScalar(
        uint256 scalarRoot,
        uint256 timeToExpiry
    ) public pure returns (uint256 rateScalar) {
        rateScalar = (scalarRoot * YEAR) / timeToExpiry;

        require(rateScalar > 0, "Invalid rate scalar");
    }

    // Required by _getRateAnchor
    // Formula used, exchangeRate(t*) = lastImpliedRate^yearsToExpiry (Pre-trade)
    function _getNextExchangeRateFromLastLnImpliedRate(
        uint256 lastLnImpliedRate,
        uint256 timeToExpiry
    ) public pure returns (int256 nextExhangeRate) {
        return
            LogExpMath.exp(((lastLnImpliedRate * timeToExpiry) / YEAR).Int());
    }

    // Required by _getExchangeRate
    // Formula used, rateAnchor = exchangeRate(t*) - ln(proportion / 1-proportion) / rateScalar
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

    // Required by swapCore
    // Formula used, exchangeRate = (ln(proportion / 1-proportion) / rateScalar) + anchorRate
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

        require(
            proportion < MAX_MARKET_PROPORTION,
            "Market proportion cannot be more than MAX_MARKET_PROPORTION"
        );

        exchangeRate =
            LogExpMath.ln(proportion.divDown(PMath.IONE - proportion)).divDown(
                rateScalar
            ) +
            rateAnchor;

        // As assetPrice is always more that PT price before expiry, and 1 at expiry
        require(exchangeRate >= PMath.IONE, "Invalid exchange rate");
    }

    // Required by swapCore After trade to set LastLnImpliedRate
    // Formula used, (ln(exchangeRate) * year) / timeToExpiry
    function _getLnImpliedRate(
        int256 totalAsset,
        int256 totalPt,
        int256 rateScalar,
        int256 rateAnchor,
        uint256 timeToExpiry
    ) public pure returns (uint256 lnImpliedRate) {
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
