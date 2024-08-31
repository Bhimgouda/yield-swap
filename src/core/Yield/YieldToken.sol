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

    // This is the read form of currentExchangeRate() which gets updated at most function calls(every other block)
    uint256 private s_exchangeRate;
    uint256 private s_exchangeRateBlock;

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
    ) external notExpired returns (uint256 amountSy) {
        return _redeemSy(receiver, amountPt, amountYt, false);
    }

    function _redeemSy(
        address receiver,
        uint256 amountPt,
        uint256 amountYt,
        bool _isExpired
    ) internal returns (uint256 amountSy) {
        if (!_isExpired) {
            require(amountPt == amountYt, "Unequal amounts of PT and YT");
            _burn(msg.sender, amountYt);
        }

        IPT(PT).burnByYt(msg.sender, amountPt);
        amountSy = previewRedeemSy(amountPt);
        ISY(SY).transfer(receiver, amountSy);

        s_syReserve -= amountSy;
    }

    function _currentExchangeRate()
        internal
        returns (uint256 currentExchangeRate)
    {
        currentExchangeRate = PMath.max(ISY(SY).exchangeRate(), s_exchangeRate);
        s_exchangeRate = currentExchangeRate;
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
    ) public view returns (uint256 amountPt, uint256 amountYt) {
        uint256 currentExchangeRate = ISY(SY).exchangeRate();

        // Formula
        // amountPtorYt = amountSy*exchangeRate (in terms of accounting asset)
        amountYt = amountSy.mulDown(currentExchangeRate);
        amountPt = amountYt;
    }

    function previewRedeemSy(
        uint256 amountPt
    ) public view returns (uint256 amountSy) {
        // Formula
        // amountSy = amountPt/exchangeRate (in terms of accounting asset)
        amountSy = amountPt.divDown(ISY(SY).exchangeRate());
    }

    /*///////////////////////////////////////////////////////////////
                            External View Functions
    //////////////////////////////////////////////////////////////*/

    function isExpired() external view returns (bool) {
        return block.timestamp < i_expiry ? false : true;
    }

    function expiry() external view returns (uint256) {
        return i_expiry;
    }

    function factory() external view returns (address) {
        return i_factory;
    }
}
