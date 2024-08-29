// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {SYWstEth} from "../../src/core/StandardisedYield/implementations/lido/SYWstEth.sol";
import {HelperConfig} from "../helpers/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract DeploySYWstEth is Script {
    function run() external returns (address) {
        HelperConfig helperConfig = new HelperConfig();
        address wstEth = helperConfig.getConfig().yieldBearingTokens[1];

        vm.startBroadcast();
        SYWstEth syWstEth = new SYWstEth("SY Lido wstETH", "SY-wstETH", wstEth);
        vm.stopBroadcast();

        return address(syWstEth);
    }
}
