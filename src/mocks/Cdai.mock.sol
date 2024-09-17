// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {PMath} from "../../lib/PMath.sol";

import {console} from "forge-std/console.sol";

/**
 * @title Cdai
 * @notice Mock for Cdai to be used in tests
 * @dev This is a GYGP model YBT (Yield Bearing Token) but with 8 decimals
 */

contract Cdai is ERC20("Compound DAI", "CDAI") {
    using PMath for uint256;

    address public immutable i_dai;
    uint256 private s_daiBalance;

    constructor(address _dai) {
        i_dai = _dai;
    }

    function mint(uint256 daiAmount) external returns (uint256 cdaiAmount) {
        if (totalSupply() > 0) {
            cdaiAmount = (daiAmount * totalSupply()) / s_daiBalance;
        } else {
            cdaiAmount = daiAmount;
        }

        s_daiBalance += daiAmount;
        _mint(msg.sender, cdaiAmount);
    }

    function redeem(uint256 cdaiAmount) external returns (uint256 daiAmount) {
        daiAmount = (s_daiBalance * cdaiAmount) / totalSupply();

        s_daiBalance -= daiAmount;
        _burn(msg.sender, cdaiAmount);
    }

    // Used in SY implementation to get exchange rate
    function exchangeRateStored() external view returns (uint256) {
        if (totalSupply() > 0) {
            return (s_daiBalance * 1e8 * 1e18) / totalSupply();
        } else {
            return 1e8 * 1e18;
        }
    }

    // To mock interest accrual
    function addInterest() external {
        if (totalSupply() > 0) {
            s_daiBalance += totalSupply().mulDown(5e15); // equivalent to adding 5% interest
        }
    }

    // Used in SY implementation to get underlying token
    function underlying() external view returns (address) {
        return address(i_dai);
    }

    function decimals() public pure override returns (uint8) {
        return 8;
    }
}

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DAI is ERC20("DAI Token", "DAI") {
    function mint(address user, uint256 amount) external {
        _mint(user, amount);
    }
}
