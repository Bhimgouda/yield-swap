// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {console} from "forge-std/console.sol";

library TokenDecimals {
    function standardize(uint256 value, uint256 tokendecimals, uint256 standardDecimals)
        internal
        pure
        returns (uint256)
    {
        if (tokendecimals == standardDecimals) return value;

        if (tokendecimals < standardDecimals) {
            return value * (10 ** (standardDecimals - tokendecimals));
        } else {
            return value / (10 ** (tokendecimals - standardDecimals));
        }
    }
}
