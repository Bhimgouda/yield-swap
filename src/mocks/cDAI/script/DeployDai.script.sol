//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {Dai} from "../src/DAI.sol";

contract DeployDai is Script {
    function run() external returns (address) {
        Dai dai = new Dai();
        return address(dai);
    }
}
