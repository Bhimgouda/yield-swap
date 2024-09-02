// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {SYWstEth} from "../../src/core/StandardisedYield/implementations/lido/SYWstEth.sol";
import {HelperConfig} from "../helpers/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract DeploySYWstEth is Script {
    function run() external returns (address SY, address yieldBearingToken) {
        HelperConfig helperConfig = new HelperConfig();
        yieldBearingToken = helperConfig.getConfig().yieldBearingTokens[1];

        vm.startBroadcast();
        SY = address(new SYWstEth("SY Lido wstETH", "SY-wstETH", yieldBearingToken));
        vm.stopBroadcast();
    }
}
