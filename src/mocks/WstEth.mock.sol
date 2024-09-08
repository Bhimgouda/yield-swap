// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IStEth} from "../interfaces/core/IStEth.sol";
import {PMath} from "../../lib/PMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract WstEth is ERC20("Wrapped liquid staked Ether 2.0", "wstETH") {
    address public stETH;

    using PMath for uint256;

    /**
     * @param _stETH address of the StETH token to wrap
     */
    constructor(address _stETH) {
        stETH = _stETH;
    }

    function wrap(uint256 stETHAmount) external returns (uint256 wstEthAmount) {
        if (totalSupply() > 0) {
            wstEthAmount =
                (stETHAmount * totalSupply()) /
                IERC20(stETH).balanceOf(address(this));
        } else {
            wstEthAmount = stETHAmount;
        }

        bool success = IERC20(stETH).transferFrom(
            msg.sender,
            address(this),
            stETHAmount
        );
        require(success, "Token transfer failed");
        _mint(msg.sender, wstEthAmount);
    }

    function unwrap(
        uint256 wstETHAmount
    ) external returns (uint256 stEthAmount) {
        stEthAmount =
            (IERC20(stETH).balanceOf(address(this)) * wstETHAmount) /
            totalSupply();
        _burn(msg.sender, wstETHAmount);
        IERC20(stETH).transfer(msg.sender, stEthAmount);
    }

    function getWstETHByStETH(
        uint256 stETHAmount
    ) external view returns (uint256) {
        if (totalSupply() > 0) {
            return
                stETHAmount.mulDown(
                    totalSupply().divDown(
                        IERC20(stETH).balanceOf(address(this))
                    )
                );
        } else {
            return 1e18;
        }
    }

    function getStETHByWstETH(
        uint256 wstETHAmount
    ) external view returns (uint256) {
        if (totalSupply() > 0) {
            return
                wstETHAmount.mulDown(
                    IERC20(stETH).balanceOf(address(this)).divDown(
                        totalSupply()
                    )
                );
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
        IERC20(stETH).transferFrom(msg.sender, address(this), stETHAmount);
    }
}
