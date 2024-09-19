// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {PMath} from "../../lib/PMath.sol";
import {console} from "forge-std/console.sol";

/**
 * @title SfPepe
 * @notice Mock for SfPepe to be used in tests
 * @dev This is a GYGP model YBT (Yield Bearing Token)
 */

contract SfPepe is ERC20("Sophon Pepe", "sfPEPE") {
    using PMath for uint256;

    address private immutable i_pepe;
    uint256 private s_pepeBalance;

    /**
     * @param _pepe address of the PEPE token to wrap
     */
    constructor(address _pepe) {
        i_pepe = _pepe;
    }

    function mint(uint256 pepeAmount) external returns (uint256 sfPepeAmount) {
        if (totalSupply() > 0) {
            sfPepeAmount = (pepeAmount * totalSupply()) / s_pepeBalance;
        } else {
            sfPepeAmount = pepeAmount;
        }

        s_pepeBalance += pepeAmount;
        _mint(msg.sender, sfPepeAmount);
    }

    function redeem(
        uint256 sfPepeAmount
    ) external returns (uint256 pepeAmount) {
        pepeAmount = (s_pepeBalance * sfPepeAmount) / totalSupply();

        s_pepeBalance -= pepeAmount;
        _burn(msg.sender, sfPepeAmount);
    }

    // Used in SY implementation to get exchange rate
    function getPepeBySfPepe(
        uint256 sfPepeAmount
    ) external view returns (uint256) {
        if (totalSupply() > 0) {
            return sfPepeAmount.mulDown(s_pepeBalance.divDown(totalSupply()));
        } else {
            return 1e18;
        }
    }

    // To mock interest accrual
    function addInterest() external {
        if (totalSupply() > 0) {
            s_pepeBalance += totalSupply().mulDown(5e12); // equivalent to adding 5% interest
        }
    }

    // Used in SY implementation to get underlying token
    function pepe() external view returns (address) {
        return i_pepe;
    }
}

contract Pepe is ERC20("Pepe", "PEPE") {
    function mint(address user, uint256 amount) external {
        _mint(user, amount);
    }
}
