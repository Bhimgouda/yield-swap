// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {PMath} from "../../lib/PMath.sol";

contract Cdai is ERC20("Compound DAI", "CDAI") {
    IERC20 public dai;

    using PMath for uint256;

    constructor(address _dai) {
        dai = IERC20(_dai);
    }

    function mint(uint256 daiAmount) external returns (uint256 cdaiAmount) {
        if (totalSupply() > 0) {
            cdaiAmount =
                (daiAmount * totalSupply()) /
                dai.balanceOf(address(this));
        } else {
            cdaiAmount = daiAmount;
        }

        bool success = dai.transferFrom(msg.sender, address(this), daiAmount);
        require(success, "Token transfer failed");
        _mint(msg.sender, cdaiAmount);
    }

    function redeem(uint256 cdaiAmount) external returns (uint256 daiAmount) {
        daiAmount = (dai.balanceOf(address(this)) * cdaiAmount) / totalSupply();
        _burn(msg.sender, cdaiAmount);
        dai.transfer(msg.sender, daiAmount);
    }

    function exchangeRateStored() external view returns (uint256) {
        if (totalSupply() > 0) {
            return dai.balanceOf(address(this)).divDown(totalSupply());
        } else {
            return 1e18;
        }
    }

    /**
     *
     * @param daiAmount Amount dai to add to the pool
     * @dev This is just a mock function that would stimulate an increase in the exchange rate of wstEth
     */
    function addInterest(uint256 daiAmount) external {
        dai.transferFrom(msg.sender, address(this), daiAmount);
    }

    function underlying() external view returns (address) {
        return address(dai);
    }

    function decimals() public view override returns (uint8) {
        return 8;
    }
}
