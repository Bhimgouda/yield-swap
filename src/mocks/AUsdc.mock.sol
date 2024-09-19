// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {PMath} from "../../lib/PMath.sol";
import {console} from "forge-std/console.sol";

/**
 * @title AUsdc
 * @notice Mock for Aave USDC to be used in tests
 * @dev This is a GYGP model YBT (Yield Bearing Token)
 */

contract AUsdc is ERC20("Aave USDC", "aUSDC") {
    using PMath for uint256;

    address private immutable i_usdc;
    uint256 private s_usdcBalance;

    /**
     * @param _usdc address of the USDC token to wrap
     */
    constructor(address _usdc) {
        i_usdc = _usdc;
    }

    function mint(uint256 usdcAmount) external returns (uint256 aUsdcAmount) {
        if (totalSupply() > 0) {
            aUsdcAmount = (usdcAmount * totalSupply()) / s_usdcBalance;
        } else {
            aUsdcAmount = usdcAmount;
        }

        s_usdcBalance += usdcAmount;
        _mint(msg.sender, aUsdcAmount);
    }

    function redeem(uint256 aUsdcAmount) external returns (uint256 usdcAmount) {
        usdcAmount = (s_usdcBalance * aUsdcAmount) / totalSupply();

        s_usdcBalance -= usdcAmount;
        _burn(msg.sender, aUsdcAmount);
    }

    // Used in SY implementation to get exchange rate
    function getUsdcByAUsdc(
        uint256 aUsdcAmount
    ) external view returns (uint256) {
        if (totalSupply() > 0) {
            return aUsdcAmount.mulDown(s_usdcBalance.divDown(totalSupply()));
        } else {
            return 1e18;
        }
    }

    // To mock interest accrual
    function addInterest() external {
        if (totalSupply() > 0) {
            s_usdcBalance += totalSupply().mulDown(5e12); // equivalent to adding 5% interest
        }
    }

    // Used in SY implementation to get underlying token
    function usdc() external view returns (address) {
        return i_usdc;
    }
}

contract USDC is ERC20("USDC", "USDC") {
    function mint(address user, uint256 amount) external {
        _mint(user, amount);
    }
}
