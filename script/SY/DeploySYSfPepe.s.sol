// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {SYSfPepe} from "../../src/core/StandardisedYield/implementations/pepe/SYSfPepe.sol";
import {HelperConfig} from "../helpers/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract DeploySYSfPepe is Script {
    function run() external returns (address SY) {
        HelperConfig helperConfig = new HelperConfig();
        address yieldBearingToken = helperConfig.run().yieldBearingTokens[4];

        vm.startBroadcast();
        SY = address(
            new SYSfPepe("SY SF-Pepe", "SY-sfPepe", yieldBearingToken)
        );
        vm.stopBroadcast();
    }
}
