// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {SYAUsdc} from "../../src/core/StandardisedYield/implementations/aave/SYAUsdc.sol";
import {HelperConfig} from "../helpers/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract DeploySYAUsdc is Script {
    function run() external returns (address SY) {
        HelperConfig helperConfig = new HelperConfig();
        address yieldBearingToken = helperConfig.run().yieldBearingTokens[2];

        vm.startBroadcast();
        SY = address(
            new SYAUsdc("SY Aave USDC", "SY-aUSDC", yieldBearingToken)
        );
        vm.stopBroadcast();
    }
}
