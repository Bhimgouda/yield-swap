// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {PMath} from "../../../lib/PMath.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ICdai} from "../../../src/interfaces/Icore/ICdai.sol";

contract TestSYCompound is Test {}
