// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {RouterYT} from "../src/router/RouterYT.sol";

contract DeployRouterYt is Script {
    function run() external returns (address) {
        vm.startBroadcast();
        RouterYT routerYT = new RouterYT();
        vm.stopBroadcast();

        return address(routerYT);
    }
}
