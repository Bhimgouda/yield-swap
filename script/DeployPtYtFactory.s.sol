// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {PtYtFactory} from "../src/core/Yield/PtYtFactory.sol";
import {DeploySyCompound} from "./SY/DeploySYCompound.s.sol";

contract DeployPtYtFactory is Script {
    function run(
        uint256 interestFeeRate,
        address treasury
    ) external returns (address) {
        vm.startBroadcast();
        PtYtFactory ptYtFactory = new PtYtFactory(interestFeeRate, treasury);
        vm.stopBroadcast();

        return address(ptYtFactory);
    }
}
