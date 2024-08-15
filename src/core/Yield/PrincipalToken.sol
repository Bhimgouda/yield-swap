// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PrincipalToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}
}
