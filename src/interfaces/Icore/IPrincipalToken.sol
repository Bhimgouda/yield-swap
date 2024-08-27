// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IPrincipalToken {
    function initialize(address yt) external;

    function mintByYt(address to, uint256 amount) external;

    function burnByYt(address from, uint256 amount) external;

    function isExpired() external view returns (bool);
}
