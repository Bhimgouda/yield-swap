// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

interface IPT is IERC20Metadata {
    function SY() external view returns (address);

    function YT() external view returns (address);

    function initialize(address yt) external;

    function mintByYt(address to, uint256 amount) external;

    function burnByYt(address from, uint256 amount) external;

    function isExpired() external view returns (bool);

    function expiry() external view returns (uint256);

    function factory() external view returns (address);
}
