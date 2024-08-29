// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {DeploySYCompound} from "./DeploySYCompound.s.sol";
import {HelperConfig} from "../helpers/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract DeployAllSY is Script {
    function run() external returns (address[] memory syTokens) {
        DeploySYCompound deploySyCompound = new DeploySYCompound();
    }
}
