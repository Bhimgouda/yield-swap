// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {LPToken} from "./LPToken.sol";

contract Market is LPToken {
    constructor(
        string memory name,
        string memory symbol
    ) LPToken(name, symbol) {}
}
