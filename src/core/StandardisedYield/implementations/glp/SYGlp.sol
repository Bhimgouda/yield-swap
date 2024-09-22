// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {SYBase} from "../../SYBase.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {console} from "forge-std/console.sol";
import {PMath} from "../../../libraries/math/PMath.sol";

contract SYGlp is SYBase {
    using PMath for uint256;
    // Yield Bearing Token Address
    address private immutable i_glp;

    // Underlying asset of the Yield Bearing Token (Accounting asset in case of GYGP model)
    address private immutable underlying;

    /**
     *
     * @param name SY Token name
     * @param symbol SY Token symbol
     * @param glp Corresponding Yield Bearing Token address
     */
    constructor(
        string memory name,
        string memory symbol,
        address glp
    ) SYBase(name, symbol) {
        i_glp = glp;
        underlying = glp;
    }

    /**
     *
     * @param amountTokenToDeposit Amount of CDAI to wrap
     */
    function _deposit(
        uint256 amountTokenToDeposit
    ) internal view override returns (uint256 amountSharesOut) {
        // This is not a 1:1 SY token as the yield token follows Simple GYGP model
        if (totalSupply() > 0) {
            amountSharesOut =
                (amountTokenToDeposit * totalSupply()) /
                IERC20Metadata(i_glp).balanceOf(address(this));
        } else {
            amountSharesOut = amountTokenToDeposit;
        }
    }

    /**
     *
     * @param amountSharesToRedeem Amount of SY to unwrap
     */
    function _redeem(
        uint256 amountSharesToRedeem
    ) internal view override returns (uint256 amountTokenOut) {
        // This is not a 1:1 SY token as the yield token follows Simple GYGP model
        amountTokenOut =
            (amountSharesToRedeem *
                IERC20Metadata(i_glp).balanceOf(address(this))) /
            totalSupply();
    }

    /**
     * @dev Provides the exchange rate of the Yield bearing token against it's underlying asset / Accounting asset
     * @notice Increase in exhange rate == Interest accrued by the Yield bearing token.
     *
     */
    function exchangeRate() external view override returns (uint256 res) {
        if (totalSupply() > 0) {
            res = IERC20Metadata(i_glp).balanceOf(address(this)).divDown(
                totalSupply()
            );
        } else {
            res = 1e18;
        }
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
        return i_glp;
    }

    function getTokensIn()
        external
        view
        override
        returns (address[] memory res)
    {
        res = new address[](1);
        res[0] = i_glp;
    }

    function getTokensOut()
        external
        view
        override
        returns (address[] memory res)
    {
        res = new address[](1);
        res[0] = i_glp;
    }

    function isValidTokenIn(address token) public view override returns (bool) {
        return token == i_glp;
    }

    function isValidTokenOut(
        address token
    ) public view override returns (bool) {
        return token == i_glp;
    }

    function assetInfo()
        external
        view
        override
        returns (AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return (AssetType.TOKEN, underlying, IERC20Metadata(i_glp).decimals());
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
