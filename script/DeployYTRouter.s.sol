// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {YTRouter} from "../src/router/YTRouter.sol";

contract DeployYTRouter is Script {
    function run() external returns (address) {
        vm.startBroadcast();
        YTRouter ytRouter = new YTRouter();
        vm.stopBroadcast();

        return address(ytRouter);
    }
}
