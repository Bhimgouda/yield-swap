// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface ISfPepe is IERC20Metadata {
    function pepe() external view returns (address);

    function getPepeBySfPepe(
        uint256 _sfPepeAmount
    ) external view returns (uint256);
}
