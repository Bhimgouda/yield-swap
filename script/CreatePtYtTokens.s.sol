// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {PtYtFactory} from "../src/core/Yield/PtYtFactory.sol";

contract DeployPtYtFactory is Script {
    function run(
        address ptYtFactory,
        address[] memory syTokens,
        uint256[] memory expiries
    ) external returns (address) {
        for (uint256 i; i < syTokens.length; ++i) {
            PtYtFactory(ptYtFactory).createPtYt(syTokens[i], expiries[i]);
        }
    }
}
