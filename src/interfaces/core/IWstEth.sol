// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IWstEth is IERC20Metadata {
    function stETH() external view returns (address);

    function wrap(uint256 _stETHAmount) external returns (uint256);

    function unwrap(uint256 _wstETHAmount) external returns (uint256);

    function getWstETHByStETH(uint256 _stETHAmount) external view returns (uint256);

    function getStETHByWstETH(uint256 _wstETHAmount) external view returns (uint256);
}
