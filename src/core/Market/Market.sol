// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.19;

// import {LPToken} from "./LPToken.sol";
// import {MarketMath, MarketState} from "./MarketMath.sol";

// import {ISY} from "../../interfaces/core/ISY.sol";
// import {IPT} from "../../interfaces/core/IPT.sol";
// import {IYT} from "../../interfaces/core/IYT.sol";

// /**
//  * @title
//  * @author
//  * @dev Market allows swaps between PT & SY it is holding.
//  * @notice A market is specific to a Yield stripping pool
//  *
//  */

// contract Market is LPToken {
//     using MarketMath for MarketState;

//     ///////////////////////
//     // CONSTANTS
//     ///////////////////////
//     string private constant NAME = "XYZ LP";
//     string private constant SYMBOL = "XYZ-LPT";
//     uint256 private constant MINIMUM_LP_RESERVE = 10 ** 5;

//     ///////////////////////
//     // IMMUTABLES
//     ///////////////////////
//     ISY public immutable SY;
//     IPT public immutable PT;
//     IYT public immutable YT;

//     uint256 private immutable i_expiry;
//     address private immutable i_factory;

//     int256 private immutable i_scalarRoot;
//     int256 private immutable i_initialAnchor;
//     uint256 private immutable i_lnFeeRateRoot;

//     ///////////////////////
//     // STORAGE
//     ///////////////////////
//     uint256 private s_totalPt;
//     uint256 private s_totalSy;
//     uint256 private s_lastLnImpliedRate; // To adjust the anchor rate pre-trade

//     constructor(
//         address _PT,
//         int256 _scalarRoot,
//         int256 _initialAnchor,
//         uint256 _lnFeeRateRoot
//     ) LPToken(NAME, SYMBOL) {
//         PT = IPT(_PT);
//         SY = ISY(PT.SY());
//         YT = IYT(PT.YT());

//         i_expiry = IPT(_PT).expiry();
//         i_factory = msg.sender;
//         i_scalarRoot = _scalarRoot;
//         i_initialAnchor = _initialAnchor;
//         i_lnFeeRateRoot = _lnFeeRateRoot;
//     }

//     modifier notExpired() {
//         require(!isExpired(), "Is Expired");
//         _;
//     }

//     /**
//      *
//      * @notice This function also sets initialImpliedRate when totalLp is 0
//      *
//      * @dev Effects totalLp, totalPt, totalSy & lastLnimpliedRate(initially)
//      */
//     function mint(
//         address receiver,
//         uint256 syDesired,
//         uint256 ptDesired
//     )
//         external
//         notExpired
//         returns (uint256 lpOut, uint256 syUsed, uint256 ptUsed)
//     {
//         // Read Market state
//         MarketState memory market = _readState();

//         // Calculate lpOut, syUsed & ptUsed
//         (lpOut, syUsed, ptUsed) = market.addLiquidity(syDesired, ptDesired);

//         // Tranfer PT & SY tokens to contract
//         PT.transferFrom(msg.sender, address(this), ptUsed);
//         SY.transferFrom(msg.sender, address(this), syUsed);

//         // If totalLp is 0, Set initialImpliedRate & mint MIN_LP to reserve
//         if (market.totalLp == 0) {
//             // SetInitialImpliedRate
//             s_lastLnImpliedRate = MarketMath.setInitialLnImpliedRate(
//                 i_scalarRoot,
//                 i_initialAnchor,
//                 syUsed,
//                 ptUsed,
//                 YT.currentSyExchangeRate(),
//                 _timeToExpiry()
//             );

//             // mint MIN_LP to reserve
//             lpOut -= MINIMUM_LP_RESERVE;
//             _mint(address(1), MINIMUM_LP_RESERVE);
//         }

//         // MintLp
//         _mint(receiver, lpOut);

//         // Update Reserves
//         s_totalSy += syUsed;
//         s_totalPt += ptUsed;
//     }

//     /**
//      *
//      * @dev steps working of this function
//         - Transfers amountPt to the pool(self)
//         - The amountSy will be precomputed by MarketMath
//         - amountSy will be transeferred to the reciever

//      * @notice The impliedRate get's changed
//      */
//     function swapSyForExactPt(
//         address receiver,
//         uint256 amountPtOut
//     ) external returns (uint256 amountSyIn, uint256 amountSyFee) {
//         address pool = address(this);
//         MarketState memory market = _readState();

//         uint256 updatedLnImpliedRate;

//         (amountSyIn, amountSyFee, updatedLnImpliedRate) = market
//             .swapSyForExactPt(
//                 amountPtOut,
//                 YT.currentSyExchangeRate(),
//                 _timeToExpiry()
//             );

//         // Write market state changes
//         s_totalSy += amountSyIn;
//         s_totalPt -= amountPtOut;
//         s_lastLnImpliedRate = updatedLnImpliedRate;

//         // Token transfers
//         SY.transferFrom(msg.sender, pool, amountSyIn);
//         PT.transfer(receiver, amountPtOut);
//     }

//     /**
//      *
//      * @dev steps working of this function
//         - Transfers amountPt to the pool(self)
//         - The amountSy will be precomputed by MarketMath
//         - amountSy will be transeferred to the reciever

//      * @notice The impliedRate get's changed
//      */
//     function swapExactPtForSy(
//         address receiver,
//         uint256 amountPtIn
//     ) external notExpired returns (uint256 amountSyOut, uint256 amountSyFee) {
//         address pool = address(this);
//         MarketState memory market = _readState();

//         uint256 updatedLnImpliedRate;

//         (amountSyOut, amountSyFee, updatedLnImpliedRate) = market
//             .swapExactPtForSy(
//                 amountPtIn,
//                 YT.currentSyExchangeRate(),
//                 _timeToExpiry()
//             );

//         // Write market state changes
//         s_totalPt += amountPtIn;
//         s_totalSy -= amountSyOut;
//         s_lastLnImpliedRate = updatedLnImpliedRate;

//         // Token transfers
//         PT.transferFrom(msg.sender, pool, amountPtIn);
//         SY.transfer(receiver, amountSyOut);
//     }

//     function burn(
//         address receiver,
//         uint256 lpAmount
//     ) external returns (uint256 syOut, uint256 ptOut) {
//         MarketState memory market = _readState();

//         (syOut, ptOut) = market.removeLiquidity(lpAmount);

//         _burn(msg.sender, lpAmount);
//         SY.transfer(receiver, syOut);
//         PT.transfer(receiver, ptOut);

//         // Update Reserves
//         s_totalSy -= syOut;
//         s_totalPt -= ptOut;
//     }

//     function _readState()
//         internal
//         view
//         returns (MarketState memory marketState)
//     {
//         marketState.totalSy = s_totalSy;
//         marketState.totalPt = s_totalPt;
//         marketState.totalLp = totalSupply();
//         marketState.lastLnImpliedRate = s_lastLnImpliedRate;
//         marketState.scalarRoot = i_scalarRoot;
//         marketState.lnFeeRateRoot = i_lnFeeRateRoot;
//         marketState.expiry = i_expiry;
//     }

//     function _timeToExpiry() internal view returns (uint256) {
//         return i_expiry - block.timestamp;
//     }

//     function isExpired() public view returns (bool) {
//         return block.timestamp >= i_expiry;
//     }

//     function expiry() external view returns (uint256) {
//         return i_expiry;
//     }

//     function factory() external view returns (address) {
//         return i_factory;
//     }
// }
