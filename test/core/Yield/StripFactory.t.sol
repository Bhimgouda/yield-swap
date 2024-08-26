// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {DeployStripFactory} from "../../../script/DeployStripFactory.s.sol";
import {IStripFactory} from "../../../src/interfaces/Icore/IStripFactory.sol";
import {console} from "forge-std/console.sol";
import {HelperConfig} from "../../../script/HelperConfig.sol";
import {DeploySyCompound} from "../../../script/SYCompound/DeploySYCompound.s.sol";

contract StripFactoryTest is Test {
    IStripFactory stripFactory;
    address syCompound;

    function setUp() external {
        DeploySyCompound deploySyCompound = new DeploySyCompound();
        syCompound = deploySyCompound.run();

        DeployStripFactory deployStripFactory = new DeployStripFactory();
        stripFactory = IStripFactory(deployStripFactory.run());
    }

    function testSomething() external {
        (
            string memory ptName,
            string memory ptSymbol,
            string memory ytName,
            string memory ytSymbol
        ) = stripFactory._generatePtYtMetadata(syCompound);

        console.log(ptName, ptSymbol, ytName, ytSymbol);
    }
}
