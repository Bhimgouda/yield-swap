// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IYT} from "../interfaces/core/IYT.sol";
import {ISY} from "../interfaces/core/ISY.sol";
import {Market} from "../core/Market/Market.sol";
import {MarketMath, MarketState, PMath} from "../core/Market/MarketMath.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {MarketApproxLib, ApproxParams} from "./MarketApproxLib.sol";

import {console} from "forge-std/console.sol";

contract MarketRouter {
    using MarketMath for MarketState;
    using PMath for uint256;

    error Market__InsufficientSyAllowance(uint256 required);

    function addLiquidity() external {}

    function removeLiquidity() external {}

    function previewAddLiquidity() external {}

    function previewRemoveLiquidity() external {}

    function swapYbtForExactPt(
        address SY,
        address ybtTokenIn,
        address market,
        uint256 amountYbtIn,
        uint256 amountPtOut
    ) external {
        address self = address(this);

        IERC20(ybtTokenIn).transferFrom(msg.sender, self, amountYbtIn);
        IERC20(ybtTokenIn).approve(SY, amountYbtIn);
        uint256 amountSy = ISY(SY).deposit(self, ybtTokenIn, amountYbtIn, 0); // Need to check 0 later

        IERC20(SY).approve(market, amountSy);
        Market(market).swapSyForExactPt(msg.sender, amountPtOut);
    }

    function swapExactPtForYbt(
        address SY,
        address ybtTokenOut,
        address market,
        uint256 amountPtIn
    ) external returns (uint256 amountYbtOut) {
        address self = address(this);

        address PT = address(Market(market).PT());
        IERC20(PT).transferFrom(msg.sender, self, amountPtIn);

        IERC20(PT).approve(market, amountPtIn);
        (uint256 amountSyOut, ) = Market(market).swapExactPtForSy(
            self,
            amountPtIn
        );

        amountYbtOut = ISY(SY).redeem(
            msg.sender,
            amountSyOut,
            ybtTokenOut,
            0,
            false
        );
    }

    function previewSwapExactPtForYbt(
        address SY,
        address ybtTokenOut,
        address market,
        uint256 amountPtIn
    ) external returns (uint256 amountYbtOut) {
        MarketState memory marketState = Market(market).readState();
        uint256 currentSyExchangeRate = Market(market).currentSyExchangeRate();

        (uint256 amountSyOut, , , ) = marketState.swapExactPtForSy(
            amountPtIn,
            currentSyExchangeRate
        );
        amountYbtOut = ISY(SY).previewRedeem(ybtTokenOut, amountSyOut);
    }

    function previewSwapExactYbtForPt(
        address SY,
        address ybtTokenIn,
        address market,
        uint256 amountYbtIn,
        uint256 guessMin,
        uint256 guessMax,
        uint256 guessOffchain
    ) public returns (uint256 amountPtOut) {
        MarketState memory marketState = Market(market).readState();
        uint256 currentSyExchangeRate = Market(market).currentSyExchangeRate();

        uint256 amountSyIn = ISY(SY).previewDeposit(ybtTokenIn, amountYbtIn);
        (amountPtOut, ) = MarketApproxLib.approxSwapExactSyForPt(
            marketState,
            currentSyExchangeRate,
            amountSyIn,
            getApproxParams(guessMin, guessMax, guessOffchain)
        );
    }

    function getApproxParams(
        uint256 guessMin,
        uint256 guessMax,
        uint256 guessOffchain
    ) private pure returns (ApproxParams memory approxParams) {
        // These are the general params for the approximation
        approxParams = ApproxParams({
            guessMin: guessMin,
            guessMax: guessMax,
            guessOffchain: guessOffchain,
            maxIteration: 30,
            eps: PMath.ONE / 10 ** 5
        });
    }
}
