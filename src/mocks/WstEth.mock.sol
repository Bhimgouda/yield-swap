// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {PMath} from "../../lib/PMath.sol";
import {console} from "forge-std/console.sol";

/**
 * @title WstEth
 * @notice Mock for WstEth to be used in tests
 * @dev This is a GYGP model YBT (Yield Bearing Token)
 */

contract WstEth is ERC20("Wrapped LST Lido", "wstETH") {
    using PMath for uint256;

    address private immutable i_stETH;
    uint256 private s_stEthBalance;

    /**
     * @param _stETH address of the StETH token to wrap
     */
    constructor(address _stETH) {
        i_stETH = _stETH;
    }

    function mint(uint256 stETHAmount) external returns (uint256 wstEthAmount) {
        if (totalSupply() > 0) {
            wstEthAmount = (stETHAmount * totalSupply()) / s_stEthBalance;
        } else {
            wstEthAmount = stETHAmount;
        }

        s_stEthBalance += stETHAmount;
        _mint(msg.sender, wstEthAmount);
    }

    function redeem(
        uint256 wstETHAmount
    ) external returns (uint256 stEthAmount) {
        stEthAmount = (s_stEthBalance * wstETHAmount) / totalSupply();

        s_stEthBalance -= stEthAmount;
        _burn(msg.sender, wstETHAmount);
    }

    // Used in SY implementation to get exchange rate
    function getStETHByWstETH(
        uint256 wstETHAmount
    ) external view returns (uint256) {
        if (totalSupply() > 0) {
            return wstETHAmount.mulDown(s_stEthBalance.divDown(totalSupply()));
        } else {
            return 1e18;
        }
    }

    // To mock interest accrual
    function addInterest() external {
        if (totalSupply() > 0) {
            s_stEthBalance += totalSupply().mulDown(5e15); // equivalent to adding 5% interest
        }
    }

    // Used in SY implementation to get underlying token
    function stETH() external view returns (address) {
        return i_stETH;
    }
}

contract StEth is ERC20("Staked Liquid Ether", "StEth") {
    function mint(address user, uint256 amount) external {
        _mint(user, amount);
    }
}
