// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {SYBase} from "../../SYBase.sol";
import {ISfPepe} from "../../../../interfaces/core/ISfPepe.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {TokenDecimals} from "../../../libraries/TokenDecimals.sol";
import {console} from "forge-std/console.sol";

contract SYSfPepe is SYBase {
    using TokenDecimals for uint256;

    uint256 private constant ONE = 1e18;

    // Yield Bearing Token Address
    address private immutable i_sfPepe;

    // Underlying asset of the Yield Bearing Token (Accounting asset in case of GYGP model)
    address private immutable underlying;

    constructor(
        string memory name,
        string memory symbol,
        address sfPepe
    ) SYBase(name, symbol) {
        i_sfPepe = sfPepe;
        underlying = ISfPepe(sfPepe).pepe();
    }

    function _deposit(
        uint256 amountTokenToDeposit
    ) internal pure override returns (uint256 amountSharesOut) {
        // This is a 1:1 SY token for GYGP yield-bearing Token
        amountSharesOut = amountTokenToDeposit;
    }

    function _redeem(
        uint256 amountSharesToRedeem
    ) internal pure override returns (uint256 amountTokenOut) {
        // This is a 1:1 SY token for GYGP yield-bearing Token
        amountTokenOut = amountSharesToRedeem;
    }

    function exchangeRate() external view override returns (uint256 res) {
        return ISfPepe(i_sfPepe).getPepeBySfPepe(ONE);
    }

    function previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) external view override returns (uint256 amountSharesOut) {
        require(isValidTokenIn(tokenIn), "Invalid TokenIn");
        amountSharesOut = _deposit(amountTokenToDeposit);
    }

    function previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    ) external view override returns (uint256 amountTokenOut) {
        require(isValidTokenOut(tokenOut), "Invalid TokenOut");
        amountTokenOut = _redeem(amountSharesToRedeem);
    }

    function yieldToken() external view override returns (address) {
        return i_sfPepe;
    }

    function getTokensIn()
        external
        view
        override
        returns (address[] memory res)
    {
        res = new address[](1);
        res[0] = i_sfPepe;
    }

    function getTokensOut()
        external
        view
        override
        returns (address[] memory res)
    {
        res = new address[](1);
        res[0] = i_sfPepe;
    }

    function isValidTokenIn(address token) public view override returns (bool) {
        return token == i_sfPepe;
    }

    function isValidTokenOut(
        address token
    ) public view override returns (bool) {
        return token == i_sfPepe;
    }

    function assetInfo()
        external
        view
        override
        returns (AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return (
            AssetType.TOKEN,
            underlying,
            IERC20Metadata(i_sfPepe).decimals()
        );
    }

    function claimRewards(
        address /* user */
    ) external pure override returns (uint256[] memory rewardAmounts) {
        return new uint256[](0);
    }

    function accruedRewards(
        address /* user */
    ) external pure override returns (uint256[] memory rewardAmounts) {
        return new uint256[](0);
    }

    function rewardIndexesCurrent()
        external
        pure
        override
        returns (uint256[] memory indexes)
    {
        return new uint256[](0);
    }

    function rewardIndexesStored()
        external
        pure
        override
        returns (uint256[] memory indexes)
    {
        return new uint256[](0);
    }

    function getRewardTokens()
        external
        pure
        override
        returns (address[] memory)
    {
        return new address[](0);
    }
}
