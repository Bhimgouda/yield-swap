// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {console} from "forge-std/console.sol";
import {PMath} from "../../../lib/PMath.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import {DeployMarketRouter} from "../../../script/DeployMarketRouter.s.sol";
import {MarketRouter} from "../../../src/router/MarketRouter.sol";
import {TestMarketSetup} from "../../helpers/TestMarketSetup.sol";

contract TestMarketRouter is TestMarketSetup {
    using PMath for uint256;

    bool internal constant ADD_LIQUIDITY_IN_TEST_SETUP = true;

    MarketRouter private marketRouter;

    function setUp() external {
        _marketTestSetup(ADD_LIQUIDITY_IN_TEST_SETUP);

        DeployMarketRouter deployMarketRouter = new DeployMarketRouter();
        marketRouter = MarketRouter(deployMarketRouter.run());
    }

    function test() external prank(USER_0) {
        marketRouter.previewSwapExactYbtForPt(
            address(SY),
            address(SY.yieldToken()),
            address(market),
            1e18,
            1023974110356682720,
            1023974110356692725,
            0
        );
    }
}
