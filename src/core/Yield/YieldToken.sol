// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {RewardManager} from "./Manager/RewardManager.sol";
import {InterestManager} from "./Manager/InterestManager.sol";
import {IPrincipalToken} from "../../interfaces/Icore/IPrincipalToken.sol";
import {IStandardizedYieldToken} from "../../interfaces/Icore/IStandardizedYieldToken.sol";
import {PMath} from "../libraries/math/PMath.sol";
import {console} from "forge-std/console.sol";

// Complies only to the GYGP model
// Is Not expired
// Takes SY -> mints YT and PT (Based on the accounting asset)
// Takes YT + PT -> SY is redeemed (before expiry)

// isExpired
// PT -> SY (Based on the accounting asset)
// YT -> Doesn't distribute the interest

/**
 * @notice The Yield Token also serves as the Yield Stripping Pool
 * holding users underlying SY, minting PT's, managing accruedInterest and rewards
 */
contract YieldToken is ERC20, InterestManager, RewardManager {
    using PMath for uint256;

    IStandardizedYieldToken private immutable SY;
    IPrincipalToken private immutable PT;
    uint256 private immutable i_expiry;

    // This is to compare current exchange rate (alias to PY index)
    uint256 private s_lastExchangeRate;
    uint256 private s_exchangeRateUpdatedBlock;

    constructor(
        address sy,
        address pt,
        string memory name,
        string memory symbol,
        uint256 expiry
    ) ERC20(name, symbol) {
        SY = IStandardizedYieldToken(sy);
        PT = IPrincipalToken(pt);
        i_expiry = expiry;
    }

    modifier isNotExpired() {
        require(block.timestamp < i_expiry, "The YT has expired");
        _;
    }

    modifier isExpired() {
        require(block.timestamp >= i_expiry, "The YT has not expired yet");
        _;
    }

    function stripSy(
        address receiver,
        uint256 amountSy
    ) external isNotExpired returns (uint256 amountPt, uint256 amountYt) {
        SY.transferFrom(msg.sender, address(this), amountSy);

        (amountYt, amountPt) = previewStrip(amountSy);

        _mint(receiver, amountYt);
        PT.mintByYt(receiver, amountPt);
    }

    /**
     *
     * @param receiver amountSy receiver
     * @param amountPt amount pt to Burn
     * @param amountYt amount yt to Burn
  
     */
    function redeemSy(
        address receiver,
        uint256 amountPt,
        uint256 amountYt
    ) external isNotExpired returns (uint256 amountSy) {
        // Burns PT and YT
        // Transfers equivalent worth of SY in terms of the accounting asset

        _burn(msg.sender, amountYt);
        PT.burnByYt(msg.sender, amountPt);

        // Need to also subtract the interest accrued
    }

    /**
     *
     * @param amountPt PT amount to Burn and Redeem equivalent worth of SY in terms of the accounting asset
     * @notice Can only be called after expiry/maturity
     */
    function redeemSyByPt(
        address receiver,
        uint256 amountPt
    ) external isExpired returns (uint256 amountSy) {
        PT.burnByYt(msg.sender, amountPt);

        amountSy = previewRedeemSyByPt(amountPt);
        SY.transfer(receiver, amountSy);
    }

    function _currentExchangeRate() internal returns (uint256) {
        uint256 currentExchangeRate = SY.exchangeRate();
        uint256 lastExchangeRate = s_lastExchangeRate;

        if (currentExchangeRate == s_lastExchangeRate) return lastExchangeRate;

        currentExchangeRate = PMath.max(currentExchangeRate, lastExchangeRate);
        s_lastExchangeRate = currentExchangeRate;

        return currentExchangeRate;
    }

    // /**
    //  *
    //  *@dev to make the YT untransferrable after expiry
    //  */
    // function _transfer(
    //     address from,
    //     address to,
    //     uint256 value
    // ) internal override isNotExpired {
    //     super._transfer(from, to, value);
    // }

    /*///////////////////////////////////////////////////////////////
                            Preview-Related FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function previewStrip(
        uint256 amountSy
    ) public view returns (uint256 amountPt, uint256 amountYt) {
        uint256 currentExchangeRate = SY.exchangeRate();

        // Formula
        // amountPtorYt = amountSy * exchangeRate (in terms of accounting asset)
        amountYt = amountSy.mulDown(currentExchangeRate);
        amountPt = amountYt;
    }

    function previewRedeem(
        uint256 amountPt
    ) public view returns (uint256 amountSy) {
        // Formula
        // amountSy = amountPt * (1/exchangeRate) (in terms of accounting asset)
        amountSy = amountPt.mulDown(PMath.ONE.divDown(SY.exchangeRate()));
    }

    function previewRedeemSyByPt(
        uint256 amountPt
    ) public view returns (uint256 amountSy) {
        // Formula
        // amountSy = amountPt * (1/exchangeRate) (in terms of accounting asset)
        amountSy = amountPt.mulDown(PMath.ONE.divDown(SY.exchangeRate()));
    }
}
