// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IStEth} from "../interfaces/core/IStEth.sol";
import {PMath} from "../../lib/PMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {console} from "forge-std/console.sol";

contract WstEth is ERC20("Wrapped liquid staked Ether 2.0", "wstETH") {
    using PMath for uint256;

    address private immutable i_stETH;
    uint256 private s_stEthBalance;

    /**
     * @param _stETH address of the StETH token to wrap
     */
    constructor(address _stETH) {
        i_stETH = _stETH;
    }

    function wrap(uint256 stETHAmount) external returns (uint256 wstEthAmount) {
        console.log(msg.sender);
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

    function getStETHByWstETH(
        uint256 wstETHAmount
    ) external view returns (uint256) {
        if (totalSupply() > 0) {
            return wstETHAmount.mulDown(s_stEthBalance.divDown(totalSupply()));
        } else {
            return 1e18;
        }
    }

    function addInterest() external {
        if (totalSupply() > 0) {
            s_stEthBalance += (totalSupply() * 5) / 100; // equivalent to adding 5% interest
        }
    }

    function stETH() external view returns (address) {
        return i_stETH;
    }
}
