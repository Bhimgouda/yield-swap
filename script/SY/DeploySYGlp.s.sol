// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {SYGlp} from "../../src/core/StandardisedYield/implementations/glp/SYGlp.sol";
import {HelperConfig} from "../helpers/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract DeploySYGlp is Script {
    function run() external returns (address SY) {
        HelperConfig helperConfig = new HelperConfig();
        address yieldBearingToken = helperConfig.run().yieldBearingTokens[5];

        vm.startBroadcast();
        SY = address(new SYGlp("SY Glp", "SY-Glp", yieldBearingToken));
        vm.stopBroadcast();
    }
}
