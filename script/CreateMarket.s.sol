// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {PtYtFactory} from "../src/core/Yield/PtYtFactory.sol";
import {MarketFactory} from "../src/core/Market/MarketFactory.sol";

// Creates PT, YT tokens for corresponding SY & expiry, also deploys a market for it.
contract CreateMarket is Script {
    function create(
        address ptYtFactory,
        address marketFactory,
        address[] memory syTokens,
        uint256[] memory expiries
    ) external returns (address[] memory markets) {
        markets = new address[](syTokens.length);

        for (uint256 i; i < syTokens.length; ++i) {
            vm.startBroadcast();

            (address PT, ) = PtYtFactory(ptYtFactory).createPtYt(
                syTokens[i],
                expiries[i]
            );

            address market = MarketFactory(marketFactory).createNewMarket(
                PT,
                179392223823000000000,
                1016557860000000000,
                499875041000000
            );

            vm.stopBroadcast();
            markets[i] = market;
        }
    }
}
