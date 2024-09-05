// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {PMath} from "../libraries/math/PMath.sol";
import {LogExpMath} from "../libraries/math/LogExpMath.sol";

struct MarketState {
    uint256 totalPt;
    uint256 totalSy;
    uint256 totalLp;
    uint256 lastLnImpliedRate;
    /// immutable variables ///
    int256 scalarRoot;
    uint256 lnFeeRateRoot;
    uint256 expiry;
}

library MarketMath {
    using PMath for uint256;
    using PMath for int256;
    using LogExpMath for int256;

    uint256 internal constant DAY = 86400;

    function addLiquidity(
        MarketState memory market,
        uint256 syDesired,
        uint256 ptDesired
    ) internal pure returns (uint256 lpOut, uint256 syUsed, uint256 ptUsed) {
        require(
            syDesired != 0 && ptDesired != 0,
            "syDesired or ptDesired cannot be 0"
        );

        // Need to Revert if Market is expired
        // if this function also gets called by the router contracts in future

        /// ------------------------------------------------------------
        /// MATH
        /// ------------------------------------------------------------

        // Formula used (Propotionality change formula - Ratio of change should be equal)
        // (x + dx) / x = (y + dy) / y
        // dy = (dx * y) / x

        uint256 lpAmountBySy = (syDesired * market.totalLp) / market.totalSy;
        uint256 lpAmountByPt = (ptDesired * market.totalLp) / market.totalPt;

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

    function removeLiquidity(
        MarketState memory market,
        uint256 lpAmount
    ) internal pure returns (uint256 syOut, uint256 ptOut) {
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

    function getInitialLnImpliedRate(
        MarketState memory market,
        uint256 index,
        int256 initialAnchor
    ) internal pure returns (uint256) {}
}
