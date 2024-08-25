//SPDX-License-identifier:MIT
pragma solidity 0.8.24;

import {SYBase} from "../../SYBase.sol";
import {ICdai} from "./ICdai.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract SYCompound is SYBase {
    // This is the yield token
    address private immutable i_Cdai;
    address private immutable underlying;

    constructor(string memory name, string memory symbol, address Cdai) SYBase(name, symbol) {
        i_Cdai = Cdai;
        underlying = ICdai(Cdai).underlying();
    }

    function _deposit(uint256 amountTokenToDeposit) internal pure override returns (uint256 amountSharesOut) {
        // This is a 1:1 SY token for GYGP yield-bearing Token
        amountSharesOut = amountTokenToDeposit;
    }

    function _redeem(uint256 amountSharesToRedeem) internal pure override returns (uint256 amountTokenOut) {
        // This is a 1:1 SY token for GYGP yield-bearing Token
        amountTokenOut = amountSharesToRedeem;
    }

    function exchangeRate() external view override returns (uint256 res) {
        return ICdai(i_Cdai).exchangeRateStored();
    }

    // Basic

    function yieldToken() external view override returns (address) {
        return i_Cdai;
    }

    function getTokensIn() external view override returns (address[] memory res) {
        res[0] = i_Cdai;
    }

    function getTokensOut() external view override returns (address[] memory res) {
        res[0] = i_Cdai;
    }

    function isValidTokenIn(address token) public view override returns (bool) {
        return token == i_Cdai;
    }

    function isValidTokenOut(address token) public view override returns (bool) {
        return token == i_Cdai;
    }

    function previewDeposit(address tokenIn, uint256 amountTokenToDeposit)
        external
        view
        override
        returns (uint256 amountSharesOut)
    {
        require(isValidTokenIn(tokenIn), "Invalid TokenIn");
        amountSharesOut = _deposit(amountTokenToDeposit);
    }

    function previewRedeem(address tokenOut, uint256 amountSharesToRedeem)
        external
        view
        override
        returns (uint256 amountTokenOut)
    {
        require(isValidTokenOut(tokenOut), "Invalid TokenOut");
        amountTokenOut = _redeem(amountSharesToRedeem);
    }

    function assetInfo()
        external
        view
        override
        returns (AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return (AssetType.TOKEN, underlying, IERC20Metadata(i_Cdai).decimals());
    }

    // Reward Related

    function claimRewards(address user) external override returns (uint256[] memory rewardAmounts) {
        return new uint256[](0);
    }

    function accruedRewards(address user) external view override returns (uint256[] memory rewardAmounts) {
        return new uint256[](0);
    }

    function rewardIndexesCurrent() external override returns (uint256[] memory indexes) {
        return new uint256[](0);
    }

    function rewardIndexesStored() external view override returns (uint256[] memory indexes) {
        return new uint256[](0);
    }

    function getRewardTokens() external view override returns (address[] memory) {
        return new address[](0);
    }
}
