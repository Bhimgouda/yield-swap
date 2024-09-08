// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {TestBase} from "./TestBase.sol";
import {console} from "forge-std/console.sol";
import {PMath} from "../../lib/PMath.sol";

import {DeploySYWstEth} from "../../script/SY/DeploySYWstEth.sol";
import {DeployPtYtFactory} from "../../script/DeployPtYtFactory.s.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import {ISY} from "../../src/interfaces/core/ISY.sol";
import {IPtYtFactory} from "../../src/interfaces/core/IPtYtFactory.sol";

interface IYieldBearingToken {
    function addInterest(uint256 stETHAmount) external;
}

contract TestYieldContracts is TestBase {
    using PMath for uint256;

    function _deploySYForTesting() internal returns (address) {
        // Deploy a SY Token for tests
        DeploySYWstEth deploySYWstEth = new DeploySYWstEth();
        address SY = deploySYWstEth.run();
        return SY;
    }

    function _deployPtYtFactory() internal returns (address) {
        DeployPtYtFactory deployPtYtFactory = new DeployPtYtFactory();
        return deployPtYtFactory.run();
    }

    function _createPtYt(
        address sy,
        uint256 expiry
    ) internal returns (address PT, address YT, address factory) {
        IPtYtFactory ptYtFactory = IPtYtFactory(_deployPtYtFactory());
        factory = address(ptYtFactory);

        // Create a Yield Stripping Pool for the SY
        (PT, YT) = ptYtFactory.createPtYt(address(sy), expiry);
    }

    // Works sy:syUnderlying is 1:1
    function _mintSYForUser(ISY sy, address user, uint256 amountSy) internal {
        // Works when sy:syUnderlying is 1:1
        uint256 amountUnderlying = amountSy;
        address syUnderlying = sy.yieldToken();

        _mintWstEthForUser(syUnderlying, user, amountUnderlying);
        IERC20(syUnderlying).approve(address(sy), amountUnderlying);

        sy.deposit(user, syUnderlying, amountUnderlying, amountSy);
    }

    function _increaseExchangeRate(
        address SY,
        uint256 increaseAmount
    ) internal returns (uint256 increasedExchangeRate) {
        address yieldBearingToken = ISY(SY).yieldToken();
        (, address underlyingToken, ) = ISY(SY).assetInfo();

        uint256 amountUnderlying = IERC20(underlyingToken).balanceOf(
            yieldBearingToken
        );

        uint256 amountUnderlyingIncrease = amountUnderlying.mulDown(
            increaseAmount
        );

        deal(
            underlyingToken,
            yieldBearingToken,
            amountUnderlying + amountUnderlyingIncrease,
            true
        );

        increasedExchangeRate = ISY(SY).exchangeRate();
    }
}
