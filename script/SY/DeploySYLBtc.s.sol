// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {SYLBtc} from "../../src/core/StandardisedYield/implementations/corn/SYLBtc.sol";
import {HelperConfig} from "../helpers/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract DeploySYLBtc is Script {
    function run() external returns (address SY) {
        HelperConfig helperConfig = new HelperConfig();
        address yieldBearingToken = helperConfig.run().yieldBearingTokens[3];

        vm.startBroadcast();
        SY = address(
            new SYLBtc("SY Lending Btc", "SY-LendingBTC", yieldBearingToken)
        );
        vm.stopBroadcast();
    }
}
