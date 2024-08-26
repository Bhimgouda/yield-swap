// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {StripFactory} from "../src/core/Yield/StripFactory.sol";

contract DeployStripFactory is Script {
    function run() external returns (address) {
        vm.startBroadcast();
        StripFactory stripFactory = new StripFactory();
        vm.stopBroadcast();

        return address(stripFactory);
    }
}
