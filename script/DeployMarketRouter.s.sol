// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {MarketRouter} from "../src/router/MarketRouter.sol";

contract DeployMarketRouter is Script {
    function run() external returns (address) {
        vm.startBroadcast();
        MarketRouter marketRouter = new MarketRouter();
        vm.stopBroadcast();

        return address(marketRouter);
    }
}
