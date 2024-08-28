// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// This is a mock Cdai (Only resembles the shares part)
// User inputs DAI
// And gets Cdai token (SHARES)
// Rewards get added in the form of DAI

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Test, console} from "forge-std/Test.sol";
import {PMath} from "../../../../src/core/libraries/math/PMath.sol";

contract Cdai is ERC20 {
    using PMath for uint256;
    // Allowed DAI token
    IERC20 private immutable DAI;

    // Block number that interest was last accrued at
    uint256 private s_accrualBlockNumber;

    // Exchange rate stored, Updates when interest is accrued
    uint256 private s_exchangeRate = 1e18;

    constructor(address dai) ERC20("Compound DAI", "cDai") {
        DAI = IERC20(dai);
    }

    function deposit(uint256 amountDAI) external returns (uint256 amountCdai) {
        // Calculating the shares to be minted
        if (totalSupply() > 0) {
            // (x + dx) / x = (y + dy) / y
            // dy = (dx * y) / x
            amountCdai =
                (amountDAI * totalSupply()) /
                DAI.balanceOf(address(this));
        } else {
            amountCdai = amountDAI;
        }

        // Adding Underlying to the pool
        DAI.transferFrom(msg.sender, address(this), amountDAI);

        // Minting Shares/Derivatives for user
        _mint(msg.sender, amountCdai);
    }

    function withdraw(uint256 amounCdai) external returns (uint256 amountDAI) {
        // Calculating DAI based on shares to be burned
        // (x - dx) / x = (y - dy) / y
        // dx = (dy * x) / y
        amountDAI = (amounCdai * DAI.balanceOf(address(this))) / totalSupply();

        // Burning the shares/derivates
        _burn(msg.sender, amounCdai);

        // Transfering the underlying asset
        DAI.transfer(msg.sender, amountDAI);
    }

    /**
     *
     * @param amountDAI Interest amount
     * @notice The exchange rate of a GYGP model only changes when the interest is being added
     */
    function accrueInterest(
        uint256 amountDAI
    ) external returns (uint256 currentExchangeRate) {
        DAI.transferFrom(msg.sender, address(this), amountDAI);
        s_accrualBlockNumber = block.number;

        // Calculate the exchange rate 1 Cdai = ? DAI
        currentExchangeRate = DAI.balanceOf(address(this)).divDown(
            totalSupply()
        );
        console.log(currentExchangeRate);
        s_exchangeRate = currentExchangeRate;
    }

    /////////////////////////
    // Required View functions for Compound Implementation
    ////////////////////////

    function exchangeRateStored() external view returns (uint256) {
        return s_exchangeRate;
    }

    function underlying() external view returns (address) {
        return address(DAI);
    }

    function accrualBlockNumber() external view returns (uint256) {
        return s_accrualBlockNumber;
    }
}
