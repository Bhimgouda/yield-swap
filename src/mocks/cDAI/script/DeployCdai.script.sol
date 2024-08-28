//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {Cdai} from "../src/Cdai.sol";

contract DeployCdai is Script {
    function run(address dai) external returns (address) {
        Cdai cdai = new Cdai(dai);
        return address(cdai);
    }
}
