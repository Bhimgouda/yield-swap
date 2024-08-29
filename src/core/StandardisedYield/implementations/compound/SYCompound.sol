// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {SYBase} from "../../SYBase.sol";
import {ICdai} from "../../../../interfaces/Icore/ICdai.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {TokenDecimals} from "../../../libraries/TokenDecimals.sol";
import {console} from "forge-std/console.sol";

contract SYCompound is SYBase {
    using TokenDecimals for uint256;

    error SYCompound__InvalidTokenIn(address expectedTokenIn);

    // Yield Bearing Token Address
    address private immutable i_cdai;

    // cdai has 8 decimals
    uint8 private immutable i_cdaiDecimals;

    // Underlying asset of the Yield Bearing Token (Accounting asset in case of GYGP model)
    address private immutable underlying;

    /**
     *
     * @param name SY Token name
     * @param symbol SY Token symbol
     * @param cdai Corresponding Yield Bearing Token address
     */
    constructor(
        string memory name,
        string memory symbol,
        address cdai
    ) SYBase(name, symbol) {
        i_cdai = cdai;
        underlying = ICdai(cdai).underlying();
        i_cdaiDecimals = IERC20Metadata(cdai).decimals();
    }

    /**
     *
     * @param amountTokenToDeposit Amount of CDAI to wrap
     */
    function _deposit(
        uint256 amountTokenToDeposit
    ) internal view override returns (uint256 amountSharesOut) {
        // This is a 1:1 SY token for GYGP yield-bearing Token
        amountSharesOut = amountTokenToDeposit.standardize(
            i_cdaiDecimals,
            decimals()
        );
    }

    /**
     *
     * @param amountSharesToRedeem Amount of SY to unwrap
     */
    function _redeem(
        uint256 amountSharesToRedeem
    ) internal view override returns (uint256 amountTokenOut) {
        // This is a 1:1 SY token for GYGP yield-bearing Token
        amountTokenOut = amountSharesToRedeem.standardize(
            decimals(),
            i_cdaiDecimals
        );
    }

    /**
     * @dev Provides the exchange rate of the Yield bearing token against it's underlying asset
     * @notice Increase in exhange rate == Interest accrued by the Yield bearing token.
     *
     * @dev The cdai exchange rate had 8 decimals (alike the token decimals). Plus has been scaled by 1e18
     */
    function exchangeRate() external view override returns (uint256 res) {
        return ICdai(i_cdai).exchangeRateStored().standardize(26, 18);
    }

    /*///////////////////////////////////////////////////////////////
                            PREVIEW RELATED FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) external view override returns (uint256 amountSharesOut) {
        if (!isValidTokenIn(tokenIn)) {
            revert SYCompound__InvalidTokenIn(tokenIn);
        }
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
        return i_cdai;
    }

    function getTokensIn()
        external
        view
        override
        returns (address[] memory res)
    {
        res = new address[](1);
        res[0] = i_cdai;
    }

    function getTokensOut()
        external
        view
        override
        returns (address[] memory res)
    {
        res = new address[](1);
        res[0] = i_cdai;
    }

    function isValidTokenIn(address token) public view override returns (bool) {
        return token == i_cdai;
    }

    function isValidTokenOut(
        address token
    ) public view override returns (bool) {
        return token == i_cdai;
    }

    function assetInfo()
        external
        view
        override
        returns (AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return (AssetType.TOKEN, underlying, i_cdaiDecimals);
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
