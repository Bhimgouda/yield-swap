// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICdai is IERC20 {
    function deposit(uint256 amountDAI) external returns (uint256 amountCdai);

    function withdraw(uint256 amounCdai) external returns (uint256 amountDAI);

    function accrueInterest(uint256 amountDAI) external returns (uint256 currentExchangeRate);

    function exchangeRateStored() external view returns (uint256);

    function underlying() external view returns (address);

    function accrualBlockNumber() external view returns (uint256);
}
