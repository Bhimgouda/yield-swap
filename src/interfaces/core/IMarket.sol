// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {MarketState} from "../../core/Market/MarketMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMarket is IERC20 {
    function SY() external view returns (address);

    function PT() external view returns (address);

    function YT() external view returns (address);

    function addLiquidity(
        address receiver,
        uint256 syDesired,
        uint256 ptDesired
    ) external returns (uint256 lpOut, uint256 syUsed, uint256 ptUsed);

    function removeLiquidity(
        address receiver,
        uint256 lpToRemove
    ) external returns (uint256 syOut, uint256 ptOut);

    function swapSyForExactPt(
        address receiver,
        uint256 amountPtOut
    ) external returns (uint256 amountSyIn, uint256 amountSyFee);

    function swapExactPtForSy(
        address receiver,
        uint256 amountPtIn
    ) external returns (uint256 amountSyOut, uint256 amountSyFee);

    function currentSyExchangeRate() external returns (uint256);

    function readState() external view returns (MarketState memory marketState);

    function isExpired() external view returns (bool);

    function expiry() external view returns (uint256);

    function factory() external view returns (address);
}
