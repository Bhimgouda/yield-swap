// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {TestBase} from "./TestBase.sol";
import {console} from "forge-std/console.sol";

import {DeploySYWstEth} from "../../script/SY/DeploySYWstEth.sol";
import {DeployPtYtFactory} from "../../script/DeployPtYtFactory.s.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import {ISY} from "../../src/interfaces/core/ISY.sol";
import {IPtYtFactory} from "../../src/interfaces/core/IPtYtFactory.sol";

contract TestYieldContracts is TestBase {
    // For Deploying PtYtFactory
    uint256 internal constant INTEREST_FEE_RATE = 1e17;
    address internal immutable TREASURY = makeAddr("TREASURY");

    function _deploySYForTesting() internal returns (address) {
        // Deploy a SY Token for tests
        DeploySYWstEth deploySYWstEth = new DeploySYWstEth();
        return deploySYWstEth.run();
    }

    function _deployPtYtFactory() internal returns (address) {
        DeployPtYtFactory deployPtYtFactory = new DeployPtYtFactory();
        return deployPtYtFactory.run(INTEREST_FEE_RATE, TREASURY);
    }

    function _createPtYt(address sy, uint256 expiry) internal returns (address PT, address YT, address factory) {
        IPtYtFactory ptYtFactory = IPtYtFactory(_deployPtYtFactory());
        factory = address(ptYtFactory);

        // Create a Yield Stripping Pool for the SY
        (PT, YT) = ptYtFactory.createPtYt(address(sy), expiry);
    }

    // Works sy:syUnderlying is 1:1
    function _mintSYForUser(ISY sy, address user, uint256 amountSy) internal {
        // Works when sy:syUnderlying is 1:1
        uint256 amountUnderlying = amountSy;

        // Minted syUnderlying/ibToken Directly

        address syUnderlying = sy.yieldToken();

        deal(syUnderlying, user, amountUnderlying, true);
        IERC20(syUnderlying).approve(address(sy), amountUnderlying);

        sy.deposit(user, syUnderlying, amountUnderlying, amountSy);
    }
}
