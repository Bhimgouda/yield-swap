// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IAUsdcToken is IERC20Metadata {
    function usdc() external view returns (address);

    function getUsdcByAUsdc(
        uint256 _aUsdcAmount
    ) external view returns (uint256);
}
