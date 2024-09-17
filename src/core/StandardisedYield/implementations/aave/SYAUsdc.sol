// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {SYBase} from "../../SYBase.sol";
import {IAUsdcToken} from "../../../../interfaces/core/IAUsdcToken.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {TokenDecimals} from "../../../libraries/TokenDecimals.sol";
import {console} from "forge-std/console.sol";

contract SYAUsdc is SYBase {
    using TokenDecimals for uint256;

    uint256 private constant ONE = 1e18;

    // Yield Bearing Token Address (aUSDC)
    address private immutable i_aUsdc;

    // Underlying asset of the Yield Bearing Token (USDC)
    address private immutable underlying;

    /**
     *
     * @param name SY Token name
     * @param symbol SY Token symbol
     * @param aUsdc Corresponding Yield Bearing Token address (aUSDC)
     */
    constructor(
        string memory name,
        string memory symbol,
        address aUsdc
    ) SYBase(name, symbol) {
        i_aUsdc = aUsdc;
        underlying = IAUsdcToken(aUsdc).usdc();
    }

    /**
     *
     * @param amountTokenToDeposit Amount of aUSDC to wrap
     */
    function _deposit(
        uint256 amountTokenToDeposit
    ) internal pure override returns (uint256 amountSharesOut) {
        // This is a 1:1 SY token for AAVE yield-bearing Token
        amountSharesOut = amountTokenToDeposit;
    }

    /**
     *
     * @param amountSharesToRedeem Amount of SY to unwrap
     */
    function _redeem(
        uint256 amountSharesToRedeem
    ) internal pure override returns (uint256 amountTokenOut) {
        // This is a 1:1 SY token for AAVE yield-bearing Token
        amountTokenOut = amountSharesToRedeem;
    }

    /**
     * @dev Provides the exchange rate of the Yield bearing token against its underlying asset
     * @notice Increase in exchange rate == Interest accrued by the Yield bearing token.
     */
    function exchangeRate() external view override returns (uint256 res) {
        return IAUsdcToken(i_aUsdc).getUsdcByAUsdc(ONE);
    }

    /*///////////////////////////////////////////////////////////////
                            PREVIEW RELATED FUNCTIONS
    //////////////////////////////////////////////////////////////*/

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

    /*///////////////////////////////////////////////////////////////
                            MISC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function yieldToken() external view override returns (address) {
        return i_aUsdc;
    }

    function getTokensIn()
        external
        view
        override
        returns (address[] memory res)
    {
        res = new address[](1);
        res[0] = i_aUsdc;
    }

    function getTokensOut()
        external
        view
        override
        returns (address[] memory res)
    {
        res = new address[](1);
        res[0] = i_aUsdc;
    }

    function isValidTokenIn(address token) public view override returns (bool) {
        return token == i_aUsdc;
    }

    function isValidTokenOut(
        address token
    ) public view override returns (bool) {
        return token == i_aUsdc;
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
            IERC20Metadata(i_aUsdc).decimals()
        );
    }

    /*///////////////////////////////////////////////////////////////
                        REWARD RELATED FUNCTIONS
    //////////////////////////////////////////////////////////////*/

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
