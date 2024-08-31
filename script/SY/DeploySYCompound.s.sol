// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {SYCompound} from "../../src/core/StandardisedYield/implementations/compound/SYCompound.sol";
import {HelperConfig} from "../helpers/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract DeploySYCompound is Script {
    function run() external returns (address) {
        HelperConfig helperConfig = new HelperConfig();
        address cDaiToken = helperConfig.getConfig().yieldBearingTokens[0];

        vm.startBroadcast();
        SYCompound syCompound = new SYCompound("SY Compound DAI", "SY-cDai", cDaiToken);
        vm.stopBroadcast();

        return address(syCompound);
    }
}
