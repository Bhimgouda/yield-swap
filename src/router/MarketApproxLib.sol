// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {MarketMath, MarketState, PMath, LogExpMath, MarketPreCompute} from "../core/Market/MarketMath.sol";

import {console} from "forge-std/console.sol";

struct ApproxParams {
    uint256 guessMin;
    uint256 guessMax;
    uint256 guessOffchain; // pass 0 in to skip this variable
    uint256 maxIteration; // every iteration, the diff between guessMin and guessMax will be divided by 2
    uint256 eps; // the max eps between the returned result & the correct result, base 1e18. Normally this number will be set
    // to 1e15 (1e18/1000 = 0.1%)
}

library MarketApproxLib {
    using MarketMath for MarketState;
    using PMath for uint256;
    using PMath for int256;
    using LogExpMath for int256;

    function approxSwapExactSyForPt(
        MarketState memory market,
        uint256 currentSyExchangeRate,
        uint256 exactSyIn,
        ApproxParams memory approx
    ) internal pure returns (uint256, /*netPtOut*/ uint256 /*netSyFee*/) {
        MarketPreCompute memory comp = market.getMarketPreCompute(
            currentSyExchangeRate
        );
        if (approx.guessOffchain == 0) {
            // no limit on min
            approx.guessMax = PMath.min(
                approx.guessMax,
                calcMaxPtOut(comp, market.totalPt.Int())
            );
            validateApprox(approx);
        }

        for (uint256 iter = 0; iter < approx.maxIteration; ++iter) {
            uint256 guess = nextGuess(approx, iter);

            (uint256 netSyIn, uint256 netSyFee, ) = calcSyIn(
                market,
                currentSyExchangeRate,
                guess
            );

            if (netSyIn <= exactSyIn) {
                if (PMath.isASmallerApproxB(netSyIn, exactSyIn, approx.eps)) {
                    return (guess, netSyFee);
                }

                approx.guessMin = guess;
            } else {
                console.log("guessMin", guess);
                approx.guessMax = guess - 1;
            }
        }

        revert("Slippage: APPROX_EXHAUSTED");
    }

    function calcMaxPtOut(
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

    function validateApprox(ApproxParams memory approx) internal pure {
        if (approx.guessMin > approx.guessMax || approx.eps > PMath.ONE)
            revert("Internal: INVALID_APPROX_PARAMS");
    }

    function nextGuess(
        ApproxParams memory approx,
        uint256 iter
    ) internal pure returns (uint256) {
        if (iter == 0 && approx.guessOffchain != 0) return approx.guessOffchain;
        if (approx.guessMin <= approx.guessMax)
            return (approx.guessMin + approx.guessMax) / 2;
        revert("Slippage: guessMin > guessMax");
    }

    function calcSyIn(
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
}
