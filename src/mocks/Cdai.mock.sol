// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {PMath} from "../../lib/PMath.sol";

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
        daiAmount = (s_daiBalance) / totalSupply();

        s_daiBalance -= daiAmount;
        _burn(msg.sender, cdaiAmount);
    }

    // Scaled by 1e18 similar to cDai
    function exchangeRateStored() external view returns (uint256) {
        if (totalSupply() > 0) {
            return (s_daiBalance * 1e28) / totalSupply();
        } else {
            return 1e8 * 1e18;
        }
    }

    function addInterest() external {
        if (totalSupply() > 0) {
            s_daiBalance += (totalSupply() * 5) / 100; // equivalent to adding 5% interest
        }
    }

    function underlying() external view returns (address) {
        return address(i_dai);
    }

    function decimals() public pure override returns (uint8) {
        return 8;
    }
}
