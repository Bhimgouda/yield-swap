// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {TestBase} from "./TestBase.sol";
import {console} from "forge-std/console.sol";
import {PMath} from "../../lib/PMath.sol";
import {LogExpMath} from "../../lib/LogExpMath.sol";

import {DeployMarketFactory} from "../../script/DeployMarketFactory.s.sol";
import {IMarketFactory} from "../../src/interfaces/core/IMarketFactory.sol";
import {IMarket} from "../../src/interfaces/core/IMarket.sol";

import {TestYield} from "./TestYield.sol";

contract TestMarketSetup is TestYield {
    using PMath for uint256;
    using LogExpMath for uint256;

    // These are co-related, and calculated off-chain
    uint256 private constant SCALAR_ROOT = 8722600000000000000;
    uint256 private constant INITIAL_ANCHOR = 1188100000000000000;
    uint256 private constant LN_FEE_RATE_ROOT = 499875041000000;
    uint256 internal constant EXPIRY = 365 days;

    uint256 private constant TOTAL_SY_FOR_EACH_POOL = 1000e18;
    uint256 private constant PT_POOL_PROPORTION = 300000000000000000; // 30% intial Proportion of PT

    IMarketFactory internal marketFactory;
    IMarket internal market;

    function _marketTestSetup(bool addLiquidity) internal {
        _yieldTestSetup();

        _deployMarketFactory();
        _createMarket();

        if (addLiquidity) {
            _addLiquidity();
        }
    }

    function _deployMarketFactory() internal {
        DeployMarketFactory deployer = new DeployMarketFactory();
        marketFactory = IMarketFactory(deployer.run(address(ptYtFactory)));
    }

    function _createMarket() internal {
        market = IMarket(
            marketFactory.createNewMarket(
                address(PT),
                SCALAR_ROOT,
                INITIAL_ANCHOR,
                LN_FEE_RATE_ROOT
            )
        );
    }

    function _addLiquidity() internal prank(USER_0) {
        uint256 totalSy = TOTAL_SY_FOR_EACH_POOL;
        uint256 amountSyToMintPt = totalSy.mulDown(PT_POOL_PROPORTION);
        uint256 amountSyForPool = totalSy - amountSyToMintPt;

        _mintSYForUser(address(SY), USER_0, totalSy);

        SY.transfer(address(YT), amountSyToMintPt);
        (uint256 amountPt, ) = YT.stripSy(USER_0, USER_0, amountSyToMintPt);

        PT.transfer(address(market), amountPt);
        SY.transfer(address(market), amountSyForPool);

        market.addLiquidity(USER_0, amountSyForPool, amountPt);
    }
}
