// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {PMath} from "../../lib/PMath.sol";
import {console} from "forge-std/console.sol";

/**
 * @title GLP Token
 * @notice Mock for GLP to be used in tests
 * @dev This is a Simple GYGP model YBT (Yield Bearing Token)
 * @notice Has no underlying asset, and interest is accrued in GLP itself and rebased
 * Which makes GLP the accounting asset
 */

contract GLP is ERC20("GMX Liquidity Provider", "GLP") {
    using PMath for uint256;

    address[] private s_users;
    mapping(address => bool) private s_isUser;

    function mint(uint256 amount) external returns (uint256 mintedAmount) {
        if (!s_isUser[msg.sender]) {
            s_users.push(msg.sender);
            s_isUser[msg.sender] = true;
        }

        _mint(msg.sender, amount);
        mintedAmount = amount;
    }

    function redeem(uint256 amount) external returns (uint256 redeemedAmount) {
        _burn(msg.sender, amount);
        redeemedAmount = amount;
    }

    // Used in SY implementation to get exchange rate
    function getExchangeRate() external pure returns (uint256) {
        return 1e18;
    }

    // To mock interest accrual
    function addInterest() external {
        uint256 totalInterest = totalSupply().mulDown(5e12);

        uint256 interestPerToken = totalInterest.divDown(totalSupply());

        for (uint256 i = 0; i < s_users.length; i++) {
            address user = s_users[i];
            uint256 userInterest = balanceOf(user).mulDown(interestPerToken);
            _mint(user, userInterest);
        }
    }
}
