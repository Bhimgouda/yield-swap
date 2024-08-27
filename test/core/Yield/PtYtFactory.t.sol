// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {DeployPtYtFactory} from "../../../script/DeployPtYtFactory.s.sol";
import {IPtYtFactory} from "../../../src/interfaces/Icore/IPtYtFactory.sol";
import {console} from "forge-std/console.sol";
import {HelperConfig} from "../../../script/HelperConfig.sol";
import {DeploySyCompound} from "../../../script/SY/DeploySYCompound.s.sol";

contract TestPtYtFactory is Test {
    IPtYtFactory internal ptYtFactory;

    uint256 private constant INITEREST_FEE_RATE = 1e17;
    address private immutable TREASURY = makeAddr("TREASURY");

    function setUp() external returns (address ptYtFactoryAddress) {
        DeployPtYtFactory deployPtYtFactory = new DeployPtYtFactory();
        ptYtFactory = IPtYtFactory(
            deployPtYtFactory.run(INITEREST_FEE_RATE, TREASURY)
        );

        ptYtFactoryAddress = address(ptYtFactory);
    }
}
