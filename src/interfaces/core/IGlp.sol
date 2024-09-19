// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface ILBtc is IERC20Metadata {
    function wBTC() external view returns (address);

    function getWBTCByLBtc(uint256 _lBtcAmount) external view returns (uint256);
}
