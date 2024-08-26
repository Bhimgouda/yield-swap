// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {DeployStripFactory} from "../../../script/DeployStripFactory.s.sol";
import {IStripFactory} from "../../../src/interfaces/Icore/IStripFactory.sol";
import {console} from "forge-std/console.sol";
import {HelperConfig} from "../../../script/HelperConfig.sol";

contract StripFactoryTest is Test {
    IStripFactory stripFactory;

    function setUp() external {
        DeployStripFactory deployStripFactory = new DeployStripFactory();
        stripFactory = IStripFactory(deployStripFactory.run());
    }

    function testSomething() external {
        HelperConfig helperConfig = new HelperConfig();
        address cdaiToken = helperConfig.getConfig().yieldBearingToken.token;

        console.log(stripFactory.getSyMetadata(cdaiToken));
    }
}
