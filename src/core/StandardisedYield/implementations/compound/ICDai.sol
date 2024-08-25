//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface ICdai {
    function exchangeRateStored() external view returns (uint256);

    function underlying() external view returns (address);
}
