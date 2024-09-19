// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {DeploySYCompound} from "./DeploySYCompound.s.sol";
import {DeploySYWstEth} from "./DeploySYWstEth.s.sol";
import {DeploySYAUsdc} from "./DeploySYAUsdc.s.sol";
import {DeploySYLBtc} from "./DeploySYLBtc.s.sol";
import {DeploySYSfPepe} from "./DeploySYSfPepe.s.sol";
import {DeploySYGlp} from "./DeploySYGlp.s.sol";

import {HelperConfig} from "../helpers/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract DeployAllSY is Script {
    function run() external returns (address[] memory syTokens) {
        DeploySYCompound deploySYCompound = new DeploySYCompound();
        DeploySYWstEth deploySYWstEth = new DeploySYWstEth();
        DeploySYAUsdc deploySYAUsdc = new DeploySYAUsdc();
        DeploySYLBtc deploySYLBtc = new DeploySYLBtc();
        DeploySYSfPepe deploySYSfPepe = new DeploySYSfPepe();
        DeploySYGlp deploySYGlp = new DeploySYGlp();

        syTokens = new address[](6);

        syTokens[0] = deploySYCompound.run();
        syTokens[1] = deploySYWstEth.run();
        syTokens[2] = deploySYAUsdc.run();
        syTokens[3] = deploySYLBtc.run();
        syTokens[4] = deploySYSfPepe.run();
        syTokens[5] = deploySYGlp.run();
    }
}
