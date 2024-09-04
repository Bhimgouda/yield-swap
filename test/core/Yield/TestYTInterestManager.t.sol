// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {TestYieldContracts} from "../../helpers/TestYieldContracts.sol";
import {console} from "forge-std/console.sol";
import {PMath} from "../../../lib/PMath.sol";

import {ISY} from "../../../src/interfaces/core/ISY.sol";
import {IYT} from "../../../src/interfaces/core/IYT.sol";
import {IPtYtFactory} from "../../../src/interfaces/core/IPtYtFactory.sol";

contract TestYTInterestManager is TestYieldContracts {
    using PMath for uint256;

    address private factory;

    ISY private sy;
    IYT private yt;

    uint256 private immutable EXPIRY = block.timestamp + (10 * DAY);
    uint256 private constant AMOUNT_SY = 1e18;
    uint256 private constant EXCHANGE_RATE_INCREASE = 20000000000000000;

    function setUp() external {
        sy = ISY(_deploySYForTesting());

        (, address YT, address _factory) = _createPtYt(address(sy), EXPIRY);
        factory = _factory;
        yt = IYT(YT);
    }

    function testIsUserAbleToRedeemDueInterest() public prank(USER) {
        // Arrange
        // _stripSy(USER, AMOUNT_SY);
        // uint256 prevExchangeRate = sy.exchangeRate();
        // _increaseExchangeRate(address(sy), EXCHANGE_RATE_INCREASE);
        // uint256 currentExchangeRate = sy.exchangeRate();
        // uint256 userStartingSyBalance = sy.balanceOf(USER);
        // // Act
        // yt.redeemDueInterest(USER);
        // uint256 userEndingSyBalance = sy.balanceOf(USER);
        // uint256 expectedInterest = _calcInterestWithFee(
        //     USER,
        //     prevExchangeRate,
        //     currentExchangeRate
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
        // uint256 prevExchangeRate = sy.exchangeRate();
        // _increaseExchangeRate(address(sy), EXCHANGE_RATE_INCREASE);
        // uint256 currentExchangeRate = sy.exchangeRate();
        // for (uint256 i; i < users.length; ++i) {
        //     address user = makeAddr(users[i]);
        //     uint256 userStartingSyBalance = sy.balanceOf(user);
        //     vm.startPrank(user);
        //     yt.redeemDueInterest(user);
        //     vm.stopPrank();
        //     uint256 userEndingSyBalance = sy.balanceOf(user);
        //     uint256 expectedInterest = _calcInterestWithFee(
        //         user,
        //         prevExchangeRate,
        //         currentExchangeRate
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
        _mintSYForUser(sy, user, amountSy);
        sy.approve(address(yt), amountSy);
        (amountPt, amountYt) = yt.stripSy(user, amountSy);
    }

    function _calcInterestWithFee(
        address user,
        uint256 prevExchangeRate,
        uint256 currentExchangeRate
    ) internal view returns (uint256) {
        uint256 interestAmount = _calcInterest(
            yt.totalSupply(),
            prevExchangeRate,
            currentExchangeRate
        );
        uint256 interestFeeRate = IPtYtFactory(factory).interestFeeRate();
        uint256 interestFee = interestAmount.mulDown(interestFeeRate);

        return
            yt.balanceOf(user).mulDown(
                (interestAmount - interestFee).divDown(yt.totalSupply())
            );
    }

    function _calcInterest(
        uint256 principal,
        uint256 prevExchangeRate,
        uint256 currentExchangeRate
    ) internal pure returns (uint256) {
        // Formula used - (principal * (current - prev))/current*prev
        return
            (principal.mulDown(currentExchangeRate - prevExchangeRate)).divDown(
                currentExchangeRate.mulDown(prevExchangeRate)
            );
    }

    function _afterExpiry() internal {
        vm.warp(EXPIRY);
    }
}
