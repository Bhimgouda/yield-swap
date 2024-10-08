// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {LPToken} from "./LPToken.sol";
import {MarketMath, MarketState} from "./MarketMath.sol";

import {ISY} from "../../interfaces/core/ISY.sol";
import {IPT} from "../../interfaces/core/IPT.sol";
import {IYT} from "../../interfaces/core/IYT.sol";
import {MarketFactory} from "./MarketFactory.sol";
import {TokenHelper} from "../libraries/TokenHelper.sol";
import {MarketRouter} from "../../router/MarketRouter.sol";

import {console} from "forge-std/console.sol";

/**
 * @title
 * @author
 * @dev Market allows swaps between PT & SY it is holding.
 * @notice A market is specific to a Yield stripping pool
 *
 */

contract Market is LPToken, TokenHelper {
    using MarketMath for MarketState;

    ///////////////////////
    // CONSTANTS
    ///////////////////////
    string private constant NAME = "XYZ LP";
    string private constant SYMBOL = "XYZ-LPT";
    uint256 private constant MINIMUM_LP_RESERVE = 10 ** 5;

    ///////////////////////
    // IMMUTABLES
    ///////////////////////
    ISY public immutable SY;
    IPT public immutable PT;
    IYT public immutable YT;

    uint256 private immutable i_expiry;
    address private immutable i_factory;

    uint256 private immutable i_scalarRoot;
    uint256 private immutable i_initialAnchor;
    uint256 private immutable i_lnFeeRateRoot;

    ///////////////////////
    // STORAGE
    ///////////////////////
    uint256 private s_totalPt;
    uint256 private s_totalSy;
    uint256 private s_lastLnImpliedRate; // To adjust the anchor rate pre-trade

    constructor(
        address _PT,
        uint256 _scalarRoot,
        uint256 _initialAnchor,
        uint256 _lnFeeRateRoot
    ) LPToken(NAME, SYMBOL) {
        PT = IPT(_PT);
        SY = ISY(PT.SY());
        YT = IYT(PT.YT());

        i_expiry = IPT(_PT).expiry();
        i_factory = msg.sender;
        i_scalarRoot = _scalarRoot;
        i_initialAnchor = _initialAnchor;
        i_lnFeeRateRoot = _lnFeeRateRoot;
    }

    modifier notExpired() {
        require(!isExpired(), "Is Expired");
        _;
    }

    /**
     * @notice syDesired & ptDesired must be transferred to this contract before calling this function
     * @notice This function also sets initialImpliedRate when totalLp is 0
     *
     * @dev Effects totalLp, totalPt, totalSy & lastLnimpliedRate(initially)
     */
    function addLiquidity(
        address receiver,
        uint256 syDesired,
        uint256 ptDesired
    )
        external
        notExpired
        returns (uint256 lpOut, uint256 syUsed, uint256 ptUsed)
    {
        MarketState memory market = readState();

        (lpOut, syUsed, ptUsed) = market.addLiquidity(syDesired, ptDesired);

        // checking if syUsed & ptUsed are transferred to this contracts
        if (_selfBalance(SY) < s_totalSy + syUsed) {
            revert("Insufficient SY Recieved here");
        }
        if (_selfBalance(PT) < s_totalPt + ptUsed) {
            revert("Insufficient PT Recieved");
        }

        // If totalLp is 0, Set initialImpliedRate & mint MIN_LP to reserve
        if (market.totalLp == 0) {
            // SetInitialImpliedRate
            s_lastLnImpliedRate = market.setInitialLnImpliedRate(
                i_initialAnchor,
                syUsed,
                ptUsed,
                currentSyExchangeRate()
            );

            // mint MIN_LP to reserve
            lpOut -= MINIMUM_LP_RESERVE;
            _mint(address(1), MINIMUM_LP_RESERVE);
        }

        // MintLp
        _mint(receiver, lpOut);

        // Update Reserves
        s_totalSy += syUsed;
        s_totalPt += ptUsed;
    }

    /**
     *
     * @notice lpToRemove must be transferred to this contract before calling this function
     */
    function removeLiquidity(
        address syReceiver,
        address ptReceiver,
        uint256 lpToRemove
    ) external returns (uint256 syOut, uint256 ptOut) {
        // checking if lpToRemove is transferred to this contracts
        if (balanceOf(address(this)) < lpToRemove) {
            revert("Insufficient LP Recieved");
        }

        MarketState memory market = readState();

        (syOut, ptOut) = market.removeLiquidity(lpToRemove);

        _burn(address(this), lpToRemove);
        SY.transfer(syReceiver, syOut);
        PT.transfer(ptReceiver, ptOut);

        // Update Reserves
        s_totalSy -= syOut;
        s_totalPt -= ptOut;
    }

    /**
     *
     * @dev steps working of this function
        - Transfers amountPt to the pool(self)
        - The amountSy will be precomputed by MarketMath
        - amountSy will be transeferred to the reciever

     * @notice Calculated amountSyIn must be transferred to this contract before calling this function
     * @notice The impliedRate get's changed
     */
    function swapSyForExactPt(
        address receiver,
        uint256 amountPtOut,
        bytes calldata data
    ) external returns (uint256 amountSyIn, uint256 amountSyFee) {
        MarketState memory market = readState();
        address treasury = MarketFactory(i_factory).treasury();

        uint256 updatedLnImpliedRate;
        uint256 amountSyToReserve;
        (
            amountSyIn,
            amountSyFee,
            amountSyToReserve,
            updatedLnImpliedRate
        ) = market.swapSyForExactPt(amountPtOut, currentSyExchangeRate());

        // Write market state changes
        s_totalSy += amountSyIn - amountSyToReserve;
        s_totalPt -= amountPtOut;
        s_lastLnImpliedRate = updatedLnImpliedRate;

        // Token transfers
        PT.transfer(receiver, amountPtOut);
        SY.transfer(treasury, amountSyToReserve);

        if (data.length > 0) {
            MarketRouter(msg.sender).swapCallback(
                amountPtOut,
                amountSyIn + amountSyFee,
                data
            );
        }

        // check if amountSyIn is transferred to this contracts
        if (_selfBalance(SY) < s_totalSy) {
            revert("Insufficient SY Recieved");
        }
    }

    /**
     *
     * @dev steps working of this function
        - Transfers amountPt to the pool(self)
        - The amountSy will be precomputed by MarketMath
        - amountSy will be transeferred to the reciever

     * @notice amountPtIn must be transferred to this contract before calling this function   
     * @notice The impliedRate get's changed
     */
    function swapExactPtForSy(
        address receiver,
        uint256 amountPtIn,
        bytes calldata data
    ) external notExpired returns (uint256 amountSyOut, uint256 amountSyFee) {
        MarketState memory market = readState();
        address treasury = MarketFactory(i_factory).treasury();

        uint256 updatedLnImpliedRate;
        uint256 amountSyToReserve;
        (
            amountSyOut,
            amountSyFee,
            amountSyToReserve,
            updatedLnImpliedRate
        ) = market.swapExactPtForSy(amountPtIn, currentSyExchangeRate());

        // Write market state changes
        s_totalPt += amountPtIn;
        s_totalSy -= amountSyOut;
        s_lastLnImpliedRate = updatedLnImpliedRate;

        // Token transfers
        SY.transfer(receiver, amountSyOut);
        SY.transfer(treasury, amountSyToReserve);

        if (data.length > 0) {
            MarketRouter(msg.sender).swapCallback(
                amountPtIn,
                amountSyOut,
                data
            );
        }

        // check if amountPtIn is transferred to this contracts
        if (_selfBalance(PT) < s_totalPt) {
            revert("Insufficient PT Recieved");
        }
    }

    function currentSyExchangeRate() public returns (uint256) {
        return YT.currentSyExchangeRate();
    }

    function readState() public view returns (MarketState memory marketState) {
        marketState.totalSy = s_totalSy;
        marketState.totalPt = s_totalPt;
        marketState.totalLp = totalSupply();
        marketState.lastLnImpliedRate = s_lastLnImpliedRate;
        marketState.scalarRoot = i_scalarRoot;
        marketState.lnFeeRateRoot = i_lnFeeRateRoot;
        marketState.timeToExpiry = timeToExpiry();
        marketState.reserveFeePercent = MarketFactory(i_factory)
            .reserveFeePercent();
    }

    function timeToExpiry() internal view returns (uint256) {
        return block.timestamp > i_expiry ? 0 : i_expiry - block.timestamp;
    }

    function isExpired() public view returns (bool) {
        return block.timestamp >= i_expiry;
    }

    function expiry() external view returns (uint256) {
        return i_expiry;
    }

    function factory() external view returns (address) {
        return i_factory;
    }
}
