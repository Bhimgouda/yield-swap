// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IWstEth is IERC20Metadata {
    function stETH() external view returns (address);

    function getStETHByWstETH(
        uint256 _wstETHAmount
    ) external view returns (uint256);
}
