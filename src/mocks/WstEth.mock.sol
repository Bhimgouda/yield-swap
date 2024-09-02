// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IStEth} from "../interfaces/core/IStEth.sol";
import {PMath} from "../../lib/PMath.sol";

contract WstEth is ERC20("Wrapped liquid staked Ether 2.0", "wstETH") {
    IStEth public stETH;

    using PMath for uint256;

    /**
     * @param _stETH address of the StETH token to wrap
     */
    constructor(address _stETH) {
        stETH = IStEth(_stETH);
    }

    function wrap(uint256 stETHAmount) external returns (uint256 wstEthAmount) {
        if (totalSupply() > 0) {
            wstEthAmount = (stETHAmount * totalSupply()) / stETH.balanceOf(address(this));
        } else {
            wstEthAmount = stETHAmount;
        }

        bool success = stETH.transferFrom(msg.sender, address(this), stETHAmount);
        require(success, "Token transfer failed");
        _mint(msg.sender, wstEthAmount);
    }

    function unwrap(uint256 wstETHAmount) external returns (uint256 stEthAmount) {
        stEthAmount = (stETH.balanceOf(address(this)) * wstETHAmount) / totalSupply();
        _burn(msg.sender, wstETHAmount);
        stETH.transfer(msg.sender, stEthAmount);
    }

    function getWstETHByStETH(uint256 stETHAmount) external view returns (uint256) {
        if (totalSupply() > 0) {
            return stETHAmount.mulDown(totalSupply().divDown(stETH.balanceOf(address(this))));
        } else {
            return 1e18;
        }
    }

    function getStETHByWstETH(uint256 wstETHAmount) external view returns (uint256) {
        if (totalSupply() > 0) {
            return wstETHAmount.mulDown(stETH.balanceOf(address(this)).divDown(totalSupply()));
        } else {
            return 1e18;
        }
    }

    /**
     *
     * @param stETHAmount Amount stEth to add to the pool
     * @dev This is just a mock function that would stimulate an increase in the exchange rate of wstEth
     */
    function addInterest(uint256 stETHAmount) external {
        stETH.transferFrom(msg.sender, address(this), stETHAmount);
    }
}
