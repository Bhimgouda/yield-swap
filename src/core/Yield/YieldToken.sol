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

    // This is the read form of currentExchangeRate() which gets updated at most function calls(every other block)
    uint256 private s_exchangeRate;
    uint256 private s_exchangeRateBlock;

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

        (amountYt, amountPt) = previewStripSy(amountSy);

        _mint(receiver, amountYt);
        PT.mintByYt(receiver, amountPt);
    }

    /**
     * @param amountPt PT amount to Burn and Redeem equivalent worth of SY in terms of the accounting asset
     * @notice Can only be called after expiry/maturity
     */
    function redeemSy(
        address receiver,
        uint256 amountPt
    ) external isExpired returns (uint256 amountSy) {
        return _redeemSy(receiver, amountPt, 0, true);
    }

    /**
     *
     * @param receiver amountSy receiver
     * @param amountPt amount pt to Burn
     * @param amountYt amount yt to Burn
     */
    function redeemSyBeforeExpiry(
        address receiver,
        uint256 amountPt,
        uint256 amountYt
    ) external isNotExpired returns (uint256 amountSy) {
        return _redeemSy(receiver, amountPt, amountYt, false);
    }

    function _redeemSy(
        address receiver,
        uint256 amountPt,
        uint256 amountYt,
        bool expired
    ) internal returns (uint256 amountSy) {
        if (!expired) {
            require(amountPt == amountYt, "Unequal amounts of PT and YT");
            _burn(msg.sender, amountYt);
        }

        PT.burnByYt(msg.sender, amountPt);
        amountSy = previewRedeemSy(amountPt);
        SY.transfer(receiver, amountSy);
    }

    function _currentExchangeRate()
        internal
        returns (uint256 currentExchangeRate)
    {
        currentExchangeRate = PMath.max(SY.exchangeRate(), s_exchangeRate);
        s_exchangeRate = currentExchangeRate;
    }

    /*///////////////////////////////////////////////////////////////
                            INTEREST & REWARD RELATED FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /*///////////////////////////////////////////////////////////////
                            Preview-Related FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    // Might need to add expiry modifiers for these public view
    function previewStripSy(
        uint256 amountSy
    ) public view returns (uint256 amountPt, uint256 amountYt) {
        uint256 currentExchangeRate = SY.exchangeRate();

        // Formula
        // amountPtorYt = amountSy * exchangeRate (in terms of accounting asset)
        amountYt = amountSy.mulDown(currentExchangeRate);
        amountPt = amountYt;
    }

    function previewRedeemSy(
        uint256 amountPt
    ) public view returns (uint256 amountSy) {
        // Formula
        // amountSy = amountPt * (1/exchangeRate) (in terms of accounting asset)
        amountSy = amountPt.mulDown(PMath.ONE.divDown(SY.exchangeRate()));
    }
}
