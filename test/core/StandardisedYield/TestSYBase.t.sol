// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {TestSY} from "../../helpers/TestSY.sol";
import {console} from "forge-std/console.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IWstEth} from "../../../src/interfaces/core/IWstEth.sol";

import {DeploySYWstEth} from "../../../script/SY/DeploySYWstEth.sol";
import {ISY} from "../../../src/interfaces/core/ISY.sol";

/**
 * @title TestSYBase
 * @author
 * @notice Using SYWstEth to test SYBase SYBase is a abstract contract
 * used by all SY implementation contracts
 */
contract TestSYBase is TestSY {
    ISY private SY;

    // The Underlying Asset
    address private wstEth;

    // SYWstEth's mint is 1:1
    uint256 AMOUNT_WSTETH_DEPOSIT = 100e18;
    uint256 AMOUNT_WSTETH_REDEEM = 100e18;
    uint256 AMOUNT_SY_MINT = 100e18;
    uint256 AMOUNT_SY_BURN = 100e18;

    function setUp() external {
        wstEth = _getWstEth();

        DeploySYWstEth deploySYWstEth = new DeploySYWstEth();
        SY = ISY(deploySYWstEth.run());
    }

    modifier deposited() {
        _mintWstEthForUser(wstEth, USER, AMOUNT_WSTETH_DEPOSIT);
        IERC20(wstEth).approve(address(SY), AMOUNT_WSTETH_DEPOSIT);
        SY.deposit(USER, wstEth, AMOUNT_WSTETH_DEPOSIT, AMOUNT_SY_MINT);
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            SYBASE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function testDeposit() external prankUser {
        _mintWstEthForUser(wstEth, USER, AMOUNT_WSTETH_DEPOSIT);

        // Arrange
        uint256 userWstEthStartBal = IERC20(wstEth).balanceOf(USER);
        uint256 userSYStartBal = SY.balanceOf(USER);
        uint256 syWstEthStartBal = IERC20(wstEth).balanceOf(address(SY));
        uint256 syStartTotalSupply = SY.totalSupply();

        // Act
        IERC20(wstEth).approve(address(SY), AMOUNT_WSTETH_DEPOSIT);
        SY.deposit(USER, wstEth, AMOUNT_WSTETH_DEPOSIT, AMOUNT_SY_MINT);

        // Assert
        uint256 userWstEthEndBal = IERC20(wstEth).balanceOf(USER);
        uint256 userSYEndBal = SY.balanceOf(USER);
        uint256 syWstEthEndBal = IERC20(wstEth).balanceOf(address(SY));
        uint256 syEndTotalSupply = SY.totalSupply();

        assertEq(userWstEthStartBal - userWstEthEndBal, AMOUNT_WSTETH_DEPOSIT);
        assertEq(userSYEndBal - userSYStartBal, AMOUNT_SY_MINT);
        assertEq(syWstEthEndBal - syWstEthStartBal, AMOUNT_WSTETH_DEPOSIT);
        assertEq(syEndTotalSupply - syStartTotalSupply, AMOUNT_SY_MINT);
    }

    function testRedeem() external prankUser deposited {
        // Arrange
        uint256 userWstEthStartBal = IERC20(wstEth).balanceOf(USER);
        uint256 userSYStartBal = SY.balanceOf(USER);
        uint256 syWstEthStartBal = IERC20(wstEth).balanceOf(address(SY));
        uint256 syStartTotalSupply = SY.totalSupply();

        // Act
        SY.redeem(USER, AMOUNT_SY_BURN, wstEth, AMOUNT_WSTETH_REDEEM, false);

        // Assert
        uint256 userWstEthEndBal = IERC20(wstEth).balanceOf(USER);
        uint256 userSYEndBal = SY.balanceOf(USER);
        uint256 syWstEthEndBal = IERC20(wstEth).balanceOf(address(SY));
        uint256 syEndTotalSupply = SY.totalSupply();

        assertEq(userWstEthEndBal - userWstEthStartBal, AMOUNT_WSTETH_REDEEM);
        assertEq(userSYStartBal - userSYEndBal, AMOUNT_SY_BURN);
        assertEq(syWstEthStartBal - syWstEthEndBal, AMOUNT_WSTETH_REDEEM);
        assertEq(syStartTotalSupply - syEndTotalSupply, AMOUNT_SY_BURN);
    }
}
