// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {MarketMath, MarketState, PMath, LogExpMath, MarketPreCompute} from "../core/Market/MarketMath.sol";
import {console} from "forge-std/console.sol";

library MarketApproxLib {
    using MarketMath for MarketState;
    using PMath for uint256;
    using PMath for int256;
    using LogExpMath for int256;

    uint256 public constant MAX_ITERATION = 30;
    uint256 public constant EPS = 1e15;
    uint256 private constant ONE = PMath.ONE;

    function approxSwapExactSyForPt(
        MarketState memory market,
        uint256 currentSyExchangeRate,
        uint256 exactSyIn
    ) internal pure returns (uint256, /*netPtOut*/ uint256 /*netSyFee*/) {
        MarketPreCompute memory comp = market.getMarketPreCompute(
            currentSyExchangeRate
        );

        uint256 guessPtMin = 0;
        uint256 guessPtMax = _calcMaxPtOut(comp, market.totalPt.Int());
        require(guessPtMin <= guessPtMax);

        for (uint256 iter = 0; iter < MAX_ITERATION; ++iter) {
            uint256 guessPt = _nextGuess(guessPtMin, guessPtMax);

            (uint256 netSyIn, uint256 netSyFee, ) = _calcSyIn(
                market,
                currentSyExchangeRate,
                guessPt
            );

            if (netSyIn <= exactSyIn) {
                if (PMath.isASmallerApproxB(netSyIn, exactSyIn, EPS)) {
                    return (guessPt, netSyFee);
                }

                guessPtMin = guessPt;
            } else {
                guessPtMax = guessPt - 1;
            }
        }

        revert("Slippage: APPROX_EXHAUSTED");
    }

    function approxSwapExactSyForYt(
        // Need 1
        MarketState memory market,
        uint256 currentSyExchangeRate,
        uint256 exactSyIn
    ) internal pure returns (uint256, /*netYtOut*/ uint256 /*netSyFee*/) {
        MarketPreCompute memory comp = market.getMarketPreCompute(
            currentSyExchangeRate
        );

        uint256 guessMin = exactSyIn.mulDown(currentSyExchangeRate);
        uint256 guessMax = _calcMaxPtIn(market, comp);
        require(guessMin <= guessMax);

        // at minimum we will flashswap exactSyIn since we have enough SY to payback the PT loan

        for (uint256 iter = 0; iter < MAX_ITERATION; ++iter) {
            uint256 guess = _nextGuess(guessMin, guessMax);

            (uint256 netSyOut, uint256 netSyFee, ) = _calcSyOut(
                market,
                comp,
                currentSyExchangeRate,
                guess
            );

            uint256 netSyToTokenizePt = guess.divDown(currentSyExchangeRate);

            // for sure netSyToTokenizePt >= netSyOut since we are swapping PT to SY
            uint256 netSyToPull = netSyToTokenizePt - netSyOut;

            if (netSyToPull <= exactSyIn) {
                if (PMath.isASmallerApproxB(netSyToPull, exactSyIn, EPS)) {
                    return (guess, netSyFee);
                }
                guessMin = guess;
            } else {
                guessMax = guess - 1;
            }
        }
        revert("Slippage: APPROX_EXHAUSTED");
    }

    function _calcMaxPtOut(
        MarketPreCompute memory comp,
        int256 totalPt
    ) internal pure returns (uint256) {
        int256 logitP = (comp.feeRate - comp.rateAnchor)
            .mulDown(comp.rateScalar)
            .exp();
        int256 proportion = logitP.divDown(logitP + PMath.IONE);
        int256 numerator = proportion.mulDown(totalPt + comp.totalAsset);
        int256 maxPtOut = totalPt - numerator;
        // only get 99.9% of the theoretical max to accommodate some precision issues
        return (uint256(maxPtOut) * 999) / 1000;
    }

    function _calcMaxPtIn(
        MarketState memory market,
        MarketPreCompute memory comp
    ) internal pure returns (uint256) {
        uint256 low = 0;
        uint256 hi = uint256(comp.totalAsset) - 1;

        while (low != hi) {
            uint256 mid = (low + hi + 1) / 2;
            if (_calcSlope(comp, market.totalPt.Int(), int256(mid)) < 0)
                hi = mid - 1;
            else low = mid;
        }

        low = PMath.min(
            low,
            (MarketMath.MAX_MARKET_PROPORTION.mulDown(
                market.totalPt.Int() + comp.totalAsset
            ) - market.totalPt.Int()).Uint()
        );

        return low;
    }

    function _calcSlope(
        MarketPreCompute memory comp,
        int256 totalPt,
        int256 ptToMarket
    ) internal pure returns (int256) {
        int256 diffAssetPtToMarket = comp.totalAsset - ptToMarket;
        int256 sumPt = ptToMarket + totalPt;

        require(diffAssetPtToMarket > 0 && sumPt > 0, "invalid ptToMarket");

        int256 part1 = (ptToMarket * (totalPt + comp.totalAsset)).divDown(
            sumPt * diffAssetPtToMarket
        );

        int256 part2 = sumPt.divDown(diffAssetPtToMarket).ln();
        int256 part3 = PMath.IONE.divDown(comp.rateScalar);

        return comp.rateAnchor - (part1 - part2).mulDown(part3);
    }

    function _nextGuess(
        uint256 guessMin,
        uint256 guessMax
    ) internal pure returns (uint256) {
        if (guessMin <= guessMax) return (guessMin + guessMax) / 2;
        revert("Slippage: guessMin > guessMax");
    }

    function _calcSyIn(
        MarketState memory market,
        uint256 currentSyExchangeRate,
        uint256 netPtOut
    )
        internal
        pure
        returns (uint256 netSyIn, uint256 netSyFee, uint256 netSyToReserve)
    {
        (netSyIn, netSyFee, netSyToReserve, ) = market.swapCore(
            netPtOut.Int(),
            currentSyExchangeRate
        );
    }

    function _calcSyOut(
        MarketState memory market,
        MarketPreCompute memory comp,
        uint256 currentSyExchangeRate,
        uint256 netPtIn
    )
        internal
        pure
        returns (uint256 netSyOut, uint256 netSyFee, uint256 netSyToReserve)
    {
        (netSyOut, netSyFee, netSyToReserve, ) = market.calcSwap(
            comp,
            -int256(netPtIn),
            currentSyExchangeRate
        );
    }
}

/** My implementation of approxSwapExactSyForYt */
/** Which was not very accurate as it was not considering the max sy loan
 * that could be taken from a pool, considering the amount of sy in the pool
 */

// function approxSwapExactSyForYt(
//     MarketState memory market,
//     uint256 currentSyExchangeRate,
//     uint256 exactSyIn
// )
//     internal
//     pure
//     returns (uint256, /* amountYtOut */ uint256 /* amountSyFee */)
// {
//     // 1. Get price of PT for 1 asset
//     // 2. YtPrice = 1 - PtPrice; as 1PT + 1YT = 1 asset
//     // 3. AmountYt = SYamount / YTPrice

//     (uint256 ptPrice, uint256 amountSyFee, , ) = market.swapExactPtForSy(
//         1e18,
//         currentSyExchangeRate
//     );

//     uint256 ptPriceInAsset = ptPrice.mulDown(currentSyExchangeRate);
//     uint256 ytPrice = (ONE - ptPriceInAsset).divDown(currentSyExchangeRate);

//     uint256 amountYtOut = exactSyIn.divDown(ytPrice);
//     return (amountYtOut, amountSyFee);
// }
