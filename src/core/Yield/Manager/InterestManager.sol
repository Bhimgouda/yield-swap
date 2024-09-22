// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {TokenHelper} from "../../libraries/TokenHelper.sol";
import {PMath} from "../../libraries/math/PMath.sol";
import {console} from "forge-std/console.sol";
import {ISY} from "../../../interfaces/core/ISY.sol";

/**
 * @dev InterestIndex in this contract represents interest per share
 */

abstract contract InterestManager is TokenHelper {
    using PMath for uint256;

    struct User {
        uint256 claimedIndex;
        uint256 accrued;
    }

    uint256 private constant INITIAL_INTEREST_INDEX = 1;

    // address => User
    mapping(address => User) private s_userInterest;

    //  ΣSummation of Interest Index
    uint256 private s_globalInterestIndex;

    // To avoid collecting interest and updating interest index within the same block
    uint256 private s_lastInterestCollectedBlock;

    function _updateAndDistributeInterest(address user) internal {
        _updateAndDistributeInterestForTwo(user, address(0));
    }

    function _updateAndDistributeInterestForTwo(
        address user1,
        address user2
    ) internal {
        uint256 globalInterestIndex = _updateGlobalInterestIndex();

        if (user1 != address(0) && user1 != address(this)) {
            _distributeInterestPrivate(user1, globalInterestIndex);
        }
        if (user2 != address(0) && user2 != address(this)) {
            _distributeInterestPrivate(user2, globalInterestIndex);
        }
    }

    function _doTransferOutInterest(
        address user,
        address SY
    ) internal returns (uint256 interestAmount) {
        interestAmount = s_userInterest[user].accrued;
        s_userInterest[user].accrued = 0;
        // _transferOut(SY, user, interestAmount);

        // Intentional
        ISY(SY).redeem(user, interestAmount, ISY(SY).yieldToken(), 0, false);
    }

    function _distributeInterestPrivate(
        address user,
        uint256 globalInterestIndex
    ) private {
        assert(user != address(0) && user != address(this));

        uint256 userClaimedInterestIndex = s_userInterest[user].claimedIndex;

        if (globalInterestIndex == userClaimedInterestIndex) return;
        if (userClaimedInterestIndex == 0) {
            s_userInterest[user].claimedIndex = globalInterestIndex;
        }

        s_userInterest[user].accrued = _ytBalanceOf(user).mulDown(
            globalInterestIndex - userClaimedInterestIndex
        );
        s_userInterest[user].claimedIndex = globalInterestIndex;
    }

    function _updateGlobalInterestIndex()
        internal
        returns (uint256 globalInterestIndex)
    {
        // Important: commented out for testing purposes
        if (block.number != s_lastInterestCollectedBlock) {
            uint256 totalShares = _ytSupply();
            uint256 interestAccrued = _collectInterest();
            globalInterestIndex = s_globalInterestIndex;

            if (totalShares != 0)
                globalInterestIndex += interestAccrued.divDown(totalShares);

            s_globalInterestIndex = globalInterestIndex;
            s_lastInterestCollectedBlock = block.number;
        } else {
            globalInterestIndex = s_globalInterestIndex;
        }
    }

    function _collectInterest()
        internal
        virtual
        returns (uint256 interestAccrued);

    function _ytBalanceOf(address user) internal view virtual returns (uint256);

    function _ytSupply() internal view virtual returns (uint256);

    /*///////////////////////////////////////////////////////////////
                            External View Functions
    //////////////////////////////////////////////////////////////*/

    function getUserInterest(address user) external view returns (User memory) {
        return s_userInterest[user];
    }

    function getGlobalInterestIndex() external view returns (uint256) {
        return s_globalInterestIndex;
    }
}
