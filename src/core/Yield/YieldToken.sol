// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {RewardManager} from "./Manager/RewardManager.sol";
import {InterestManager} from "./Manager/InterestManager.sol";
import {IPT} from "../../interfaces/core/IPT.sol";
import {ISY} from "../../interfaces/core/ISY.sol";
import {PMath} from "../libraries/math/PMath.sol";
import {console} from "forge-std/console.sol";

// Complies only to the GYGP model
// Is Not expired
// Takes SY -> mints YT and PT (Based on the accounting asset)
// Takes YT + PT -> SY is redeemed (before expiry)

// expired
// PT -> SY (Based on the accounting asset)
// YT -> Doesn't distribute the interest

/**
 * @notice The Yield Token also serves as the Yield Stripping Pool
 * holding users underlying SY, minting PT's, managing accruedInterest and rewards
 */
contract YieldToken is ERC20, InterestManager, RewardManager {
    using PMath for uint256;

    address public immutable SY;
    address public immutable PT;
    address public immutable i_factory;
    uint256 private immutable i_expiry;

    uint256 private s_syReserve;

    // Used to store the non-decreasing form of SY.exchangeRate()
    uint256 private s_storedExchangeRate;

    // uint256 private s_storedExchangeRateUpdatedBlock; // check currentExchangeRate() for reaseon

    constructor(
        address _SY,
        address _PT,
        string memory _name,
        string memory _symbol,
        uint256 _expiry
    ) ERC20(_name, _symbol) {
        SY = _SY;
        PT = _PT;
        i_expiry = _expiry;
        i_factory = msg.sender;
    }

    modifier notExpired() {
        require(block.timestamp < i_expiry, "The YT has expired");
        _;
    }

    modifier expired() {
        require(block.timestamp >= i_expiry, "The YT has not expired yet");
        _;
    }

    function stripSy(
        address receiver,
        uint256 amountSy
    ) external notExpired returns (uint256 amountPt, uint256 amountYt) {
        ISY(SY).transferFrom(msg.sender, address(this), amountSy);

        (amountYt, amountPt) = previewStripSy(amountSy);

        _mint(receiver, amountYt);
        IPT(PT).mintByYt(receiver, amountPt);

        s_syReserve += amountSy;
    }

    /**
     * @param amountPt PT amount to Burn and Redeem equivalent worth of SY in terms of the accounting asset
     * @notice Can only be called after expiry/maturity
     */
    function redeemSy(
        address receiver,
        uint256 amountPt
    ) external expired returns (uint256 amountSy) {
        return _redeemSy(receiver, amountPt, amountPt);
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
    ) external notExpired returns (uint256 amountSy) {
        return _redeemSy(receiver, amountPt, amountYt);
    }

    function _redeemSy(
        address receiver,
        uint256 amountPt,
        uint256 amountYt
    ) internal returns (uint256 amountSy) {
        if (!isExpired()) {
            // Considering the minimum to be burnt
            (amountPt, amountYt) = _getAdjustedPtYt(amountPt, amountYt);
        }

        IPT(PT).burnByYt(msg.sender, amountPt);
        _burn(msg.sender, amountYt);

        amountSy = previewRedeemSy(amountPt);
        ISY(SY).transfer(receiver, amountSy);

        s_syReserve -= amountSy;
    }

    // IMPORTANT - Need Clarity
    // The SY exchange rate should be non-decreaing
    // which is why we have stored exchange rate for reference

    // IMPORTANT Has been changed - I feel currentExchangeRate can be
    // different within same block
    // that's why they also have cacheWithinSameblock option (That's why I commented it)
    function currentExchangeRate()
        public
        returns (uint256 _currentExchangeRate)
    {
        // if (block.number == s_storedExchangeRateUpdatedBlock)
        //     return currentExchangeRate = s_storedExchangeRate;

        _currentExchangeRate = PMath.max(
            ISY(SY).exchangeRate(),
            s_storedExchangeRate
        );

        s_storedExchangeRate = _currentExchangeRate;
        // s_storedExchangeRateUpdatedBlock = block.number;
    }

    function _getAdjustedPtYt(
        uint256 _amountPt,
        uint256 _amountYt
    ) internal pure returns (uint256 amountPt, uint256 amountYt) {
        uint256 minAmount = PMath.min(_amountPt, _amountYt);

        amountPt = minAmount;
        amountYt = minAmount;
    }

    /*///////////////////////////////////////////////////////////////
                            INTEREST-RELATED FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /*///////////////////////////////////////////////////////////////
                            Preview-Related FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    // Might need to add expiry modifiers for these public view
    function previewStripSy(
        uint256 amountSy
    ) public returns (uint256 amountPt, uint256 amountYt) {
        // Formula
        // amountPtorYt = amountSy*exchangeRate (in terms of accounting asset)
        amountYt = amountSy.mulDown(currentExchangeRate());
        amountPt = amountYt;
    }

    function previewRedeemSy(
        uint256 amountPt
    ) public returns (uint256 amountSy) {
        // Formula
        // amountSy = amountPt/exchangeRate (in terms of accounting asset)
        amountSy = amountPt.divDown(currentExchangeRate());
    }

    function previewRedeemSyBeforeExpiry(
        uint256 amountPt,
        uint256 amountYt
    ) public returns (uint256 amountSy) {
        (amountPt, ) = _getAdjustedPtYt(amountPt, amountYt);
        amountSy = previewRedeemSy(amountPt);
    }

    /*///////////////////////////////////////////////////////////////
                            External View Functions
    //////////////////////////////////////////////////////////////*/

    function isExpired() public view returns (bool) {
        return block.timestamp < i_expiry ? false : true;
    }

    function expiry() external view returns (uint256) {
        return i_expiry;
    }

    function factory() external view returns (address) {
        return i_factory;
    }

    function syReserve() external view returns (uint256) {
        return s_syReserve;
    }
}
