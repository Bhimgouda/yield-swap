//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract SYBase is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}
}
