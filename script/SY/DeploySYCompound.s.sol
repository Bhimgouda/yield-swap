// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {SYCompound} from "../../src/core/StandardisedYield/implementations/compound/SYCompound.sol";
import {HelperConfig} from "../helpers/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract DeploySYCompound is Script {
    function run() external returns (address SY) {
        HelperConfig helperConfig = new HelperConfig();
        address yieldBearingToken = helperConfig.run().yieldBearingTokens[0];

        vm.startBroadcast();
        SY = address(
            new SYCompound("SY Compound DAI", "SY-cDai", yieldBearingToken)
        );
        vm.stopBroadcast();
    }
}
