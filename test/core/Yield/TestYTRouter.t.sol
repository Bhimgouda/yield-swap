// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {TestYield} from "../../helpers/TestYield.sol";
import {console} from "forge-std/console.sol";
import {PMath} from "../../../lib/PMath.sol";
import {DeployYTRouter} from "../../../script/DeployYTRouter.s.sol";
import {YTRouter} from "../../../src/router/YTRouter.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract TestYTRouter is TestYield {
    using PMath for uint256;

    YTRouter private ytRouter;
    uint256 private amountYt;

    uint256 private INTEREST_PERCENTAGE = 5e15; // 0.5%

    function setUp() external {
        _yieldTestSetup();

        DeployYTRouter deployYTRouter = new DeployYTRouter();
        ytRouter = YTRouter(deployYTRouter.run());
    }

    function _mintYtForUser() internal {
        _mintSYForUser(address(SY), USER_0, AMOUNT_SY);
        SY.approve(address(YT), AMOUNT_SY);
        (, amountYt) = YT.stripSy(USER_0, AMOUNT_SY);
    }

    function testPreviewDueInterest() external prank(USER_0) {
        _mintYtForUser();

        _addInterest();

        console.log("prevYbtBalance", YBT.balanceOf(USER_0));
        uint256 interestOut = YT.redeemDueInterest(USER_0);
        console.log("interestOut", interestOut);
        console.log("currentYbtBalance", YBT.balanceOf(USER_0));
    }
}
