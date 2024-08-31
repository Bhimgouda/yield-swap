// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

interface IPT is IERC20Metadata {
    function initialize(address yt) external;

    function mintByYt(address to, uint256 amount) external;

    function burnByYt(address from, uint256 amount) external;

    function isExpired() external view returns (bool);

    function getSY() external view returns (address);

    function getYT() external view returns (address);

    function getExpiry() external view returns (uint256);

    function getFactory() external view returns (address);
}
