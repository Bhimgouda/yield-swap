// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {MarketFactory} from "../src/core/market/MarketFactory.sol";

contract DeployMarketFactory is Script {
    function run(address ptYtFactory) external returns (address) {
        address treasury = makeAddr("TREASURY");
        uint256 reserveFeePercent = 80;

        vm.startBroadcast();
        MarketFactory marketFactory = (
            new MarketFactory(ptYtFactory, treasury, reserveFeePercent)
        );
        vm.stopBroadcast();

        return address(marketFactory);
    }
}
