// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {LPToken} from "./LPToken.sol";

/**
 * @title
 * @author
 * @notice This is a market for PT and it's corresponding SY
 */

contract Market is LPToken {
    ///////////////////////
    // CONSTANTS
    ///////////////////////
    string private constant NAME = "XYZ LP";
    string private constant SYMBOL = "XYZ-LPT";

    constructor(
        address _PT,
        int256 _scalarRoot,
        int256 _initialAnchor,
        uint256 _lnFeeRateRoot
    ) LPToken(NAME, SYMBOL) {}
}
