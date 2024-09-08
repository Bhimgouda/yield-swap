// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {PtYtFactory} from "../src/core/Yield/PtYtFactory.sol";

contract DeployPtYtFactory is Script {
    function run() external returns (address) {
        uint256 INTEREST_FEE_RATE = 1e17;
        address TREASURY = makeAddr("TREASURY");

        vm.startBroadcast();
        PtYtFactory ptYtFactory = new PtYtFactory(INTEREST_FEE_RATE, TREASURY);
        vm.stopBroadcast();

        return address(ptYtFactory);
    }
}
