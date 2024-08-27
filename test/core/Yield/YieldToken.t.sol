// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {HelperConfig} from "../../../script/HelperConfig.sol";
import {DeploySyCompound} from "../../../script/SY/DeploySYCompound.s.sol";
import {TestPtYtFactory} from "./PtYtFactory.t.sol";
import {IYieldToken} from "../../../src/interfaces/Icore/IYieldToken.sol";
import {IPtYtFactory} from "../../../src/interfaces/Icore/IPtYtFactory.sol";
import {DeployPtYtFactory} from "../../../script/DeployPtYtFactory.s.sol";

contract TestYieldToken is Test {
    IYieldToken private ytCdai;

    uint256 private constant INTEREST_FEE_RATE = 1e17;
    address private immutable TREASURY = makeAddr("TREASURY");

    function setUp() external {
        DeployPtYtFactory deployPtYtFactory = new DeployPtYtFactory();
        IPtYtFactory ptYtFactory = IPtYtFactory(
            deployPtYtFactory.run(INTEREST_FEE_RATE, TREASURY)
        );

        DeploySyCompound deploySyCompound = new DeploySyCompound();
        address syCompound = deploySyCompound.run();

        (, address yt) = ptYtFactory.createPtYt(
            syCompound,
            block.timestamp + (10 * 86400)
        );

        ytCdai = IYieldToken(yt);
    }

    function testPreviewRedeem() external view {
        console.log(ytCdai.previewRedeemSyByPt(1e18));
    }
}
