// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IYBT is IERC20 {
    function mint(uint256 stETHAmount) external returns (uint256 wstEthAmount);

    function redeem(
        uint256 wstETHAmount
    ) external returns (uint256 stEthAmount);

    function addInterest() external;
}
