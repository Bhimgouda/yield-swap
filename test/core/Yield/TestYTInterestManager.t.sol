// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {TestYield} from "../../helpers/TestYield.sol";
import {console} from "forge-std/console.sol";
import {PMath} from "../../../lib/PMath.sol";

contract TestYTInterestManager is TestYield {
    using PMath for uint256;

    function setUp() external {
        _yieldTestSetup();
    }

    function testIsUserAbleToRedeemDueInterest() public prank(USER_0) {
        // Arrange
        // _stripSy(USER_0, AMOUNT_SY);
        // uint256 prevExchangeRate = SY.exchangeRate();
        // _increaseExchangeRate(address(SY), EXCHANGE_RATE_INCREASE);
        // uint256 currentSyExchangeRate = SY.exchangeRate();
        // uint256 userStartingSyBalance = SY.balanceOf(USER_0);
        // // Act
        // YT.redeemDueInterest(USER_0);
        // uint256 userEndingSyBalance = SY.balanceOf(USER_0);
        // uint256 expectedInterest = _calcInterestWithFee(
        //     USER_0,
        //     prevExchangeRate,
        //     currentSyExchangeRate
        // );
        // // console.log(userEndingSyBalance, expectedInterest);
        // assertEq(userEndingSyBalance - userStartingSyBalance, expectedInterest);
    }

    function testUserIsAbleToRedeemDueInterestMultipleTimes() external {
        // for (uint i; i < 5; ++i) {
        //     testIsUserAbleToRedeemDueInterest();
        // }
    }

    function testMultipleUsersAbleToRedeem() external {
        // string[5] memory users = ["USER1", "USER2", "USER3", "USER4", "USER5"];
        // for (uint256 i; i < users.length; ++i) {
        //     address user = makeAddr(users[i]);
        //     vm.startPrank(user);
        //     _stripSy(user, (i + 1) * AMOUNT_SY);
        //     vm.stopPrank();
        // }
        // uint256 prevExchangeRate = SY.exchangeRate();
        // _increaseExchangeRate(address(SY), EXCHANGE_RATE_INCREASE);
        // uint256 currentSyExchangeRate = SY.exchangeRate();
        // for (uint256 i; i < users.length; ++i) {
        //     address user = makeAddr(users[i]);
        //     uint256 userStartingSyBalance = SY.balanceOf(user);
        //     vm.startPrank(user);
        //     YT.redeemDueInterest(user);
        //     vm.stopPrank();
        //     uint256 userEndingSyBalance = SY.balanceOf(user);
        //     uint256 expectedInterest = _calcInterestWithFee(
        //         user,
        //         prevExchangeRate,
        //         currentSyExchangeRate
        //     );
        //     assertEq(
        //         userEndingSyBalance - userStartingSyBalance,
        //         expectedInterest
        //     );
        // }
    }

    function _stripSy(
        address user,
        uint256 amountSy
    ) internal returns (uint256 amountPt, uint256 amountYt) {
        _mintSYForUser(address(SY), USER_0, amountSy);
        SY.approve(address(YT), amountSy);
        (amountPt, amountYt) = YT.stripSy(user, user, amountSy);
    }

    function _calcInterestWithFee(
        address user,
        uint256 prevExchangeRate,
        uint256 currentSyExchangeRate
    ) internal view returns (uint256) {
        uint256 interestAmount = _calcInterest(
            YT.totalSupply(),
            prevExchangeRate,
            currentSyExchangeRate
        );
        uint256 interestFeeRate = ptYtFactory.interestFeeRate();
        uint256 interestFee = interestAmount.mulDown(interestFeeRate);

        return
            YT.balanceOf(user).mulDown(
                (interestAmount - interestFee).divDown(YT.totalSupply())
            );
    }

    function _calcInterest(
        uint256 principal,
        uint256 prevExchangeRate,
        uint256 currentSyExchangeRate
    ) internal pure returns (uint256) {
        // Formula used - (principal * (current - prev))/current*prev
        return
            (principal.mulDown(currentSyExchangeRate - prevExchangeRate))
                .divDown(currentSyExchangeRate.mulDown(prevExchangeRate));
    }

    function _afterExpiry() internal {
        vm.warp(EXPIRY_DURATION);
    }
}
