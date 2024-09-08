// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {DeployPtYtFactory} from "./DeployPtYtFactory.s.sol";
import {DeployMarketFactory} from "./DeployMarketFactory.s.sol";
import {DeployAllSY} from "./SY/DeployAllSY.s.sol";
import {CreateMarket} from "./CreateMarket.s.sol";
import {console} from "forge-std/console.sol";

contract Demo is Script {
    uint256 private constant DAY = 86400;

    function run() external {
        DeployPtYtFactory deployPtYtFactory = new DeployPtYtFactory();
        DeployMarketFactory deployMarketFactory = new DeployMarketFactory();
        DeployAllSY deployAllSY = new DeployAllSY();
        CreateMarket createMarket = new CreateMarket();

        address ptYtFactory = deployPtYtFactory.run();
        address marketFactory = deployMarketFactory.run(ptYtFactory);
        address[] memory syTokens = deployAllSY.run();
        uint256[] memory expiries = new uint256[](syTokens.length);

        for (uint256 i; i < syTokens.length; ++i) {
            expiries[i] = block.timestamp + (10 * DAY);
        }

        // Creates PT, YT tokens for corresponding SY & expiry, also deploys a market for it.
        address[] memory markets = createMarket.create(
            ptYtFactory,
            marketFactory,
            syTokens,
            expiries
        );

        // market object
        string memory market = vm.toString(block.chainid);

        for (uint256 i = 0; i < syTokens.length; i++) {
            if (i == syTokens.length - 1) {
                market = vm.serializeAddress(
                    market,
                    vm.toString(i),
                    markets[i]
                );
            } else {
                vm.serializeAddress(market, vm.toString(i), markets[i]);
            }
        }

        vm.writeJson(market, "./address/markets.json");
    }
}
