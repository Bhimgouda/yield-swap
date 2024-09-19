// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {PMath} from "../../lib/PMath.sol";
import {console} from "forge-std/console.sol";

/**
 * @title lBTC
 * @notice Mock for lBTC to be used in tests
 * @dev This is a GYGP model YBT (Yield Bearing Token)
 */

contract LBtc is ERC20("Lombard BTC (CORN)", "lBTC") {
    using PMath for uint256;

    address private immutable i_wBTC;
    uint256 private s_wBTCBalance;

    /**
     * @param _wBTC address of the WBTC token to wrap
     */
    constructor(address _wBTC) {
        i_wBTC = _wBTC;
    }

    function mint(uint256 wBTCAmount) external returns (uint256 lBTCAmount) {
        if (totalSupply() > 0) {
            lBTCAmount = (wBTCAmount * totalSupply()) / s_wBTCBalance;
        } else {
            lBTCAmount = wBTCAmount;
        }

        s_wBTCBalance += wBTCAmount;
        _mint(msg.sender, lBTCAmount);
    }

    function redeem(uint256 lBTCAmount) external returns (uint256 wBTCAmount) {
        wBTCAmount = (s_wBTCBalance * lBTCAmount) / totalSupply();

        s_wBTCBalance -= wBTCAmount;
        _burn(msg.sender, lBTCAmount);
    }

    // Used in SY implementation to get exchange rate
    function getWBTCByLBtc(uint256 lBTCAmount) external view returns (uint256) {
        if (totalSupply() > 0) {
            return lBTCAmount.mulDown(s_wBTCBalance.divDown(totalSupply()));
        } else {
            return 1e18;
        }
    }

    // To mock interest accrual
    function addInterest() external {
        if (totalSupply() > 0) {
            s_wBTCBalance += totalSupply().mulDown(5e12); // equivalent to adding 5% interest
        }
    }

    // Used in SY implementation to get underlying token
    function wBTC() external view returns (address) {
        return i_wBTC;
    }
}

contract WBTC is ERC20("Wrapped Bitcoin", "WBTC") {
    function mint(address user, uint256 amount) external {
        _mint(user, amount);
    }
}
