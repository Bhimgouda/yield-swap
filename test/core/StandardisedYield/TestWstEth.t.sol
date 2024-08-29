// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {PMath} from "../../../lib/PMath.sol";
import {TestBase} from "../../helpers/TestBase.sol";
import {HelperConfig} from "../../../script/helpers/HelperConfig.s.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IWstEth} from "../../../src/interfaces/Icore/IWstEth.sol";

import {DeploySYWstEth} from "../../../script/SY/DeploySYWstEth.sol";
import {IStandardizedYieldToken} from "../../../src/interfaces/Icore/IStandardizedYieldToken.sol";

contract TestSY is Test, TestBase {
    IStandardizedYieldToken private SY;

    // The Underlying Asset
    address private wstEth;

    // SY mint is 1:1
    uint256 AMOUNT_WSTETH_DEPOSIT = 100e18;
    uint256 AMOUNT_WSTETH_REDEEM = 100e18;
    uint256 AMOUNT_SY_MINT = 100e18;
    uint256 AMOUNT_SY_BURN = 100e18;

    function setUp() external {
        HelperConfig helperConfig = new HelperConfig();
        wstEth = helperConfig.getConfig().yieldBearingTokens[1];

        DeploySYWstEth deploySYWstEth = new DeploySYWstEth();
        SY = IStandardizedYieldToken(deploySYWstEth.run());
    }

    modifier deposited() {
        _mintWstEthForUser(wstEth, USER, AMOUNT_WSTETH_DEPOSIT);
        IERC20(wstEth).approve(address(SY), AMOUNT_WSTETH_DEPOSIT);
        SY.deposit(USER, wstEth, AMOUNT_WSTETH_DEPOSIT, AMOUNT_SY_MINT);
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            SYBase FUNCTIONS
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

    /*///////////////////////////////////////////////////////////////
                            PREVIEW RELATED FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    // NEED CLARITY
    function testExchangeRate() external view {
        uint256 exchangeRate = SY.exchangeRate();

        // So we divide it by 1e8 to make it comply to our SY.exchangeRate()
        uint256 expectedExchangeRate = IWstEth(wstEth).getStETHByWstETH(ONE);
        assertEq(exchangeRate, expectedExchangeRate);
    }

    /*///////////////////////////////////////////////////////////////
                            PREVIEW RELATED FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function testPreviewDeposit() external {
        uint256 amountSY = SY.previewDeposit(wstEth, AMOUNT_WSTETH_DEPOSIT);
        uint256 expectedamountSY = AMOUNT_SY_MINT;

        assertEq(amountSY, expectedamountSY);

        // REVERT TEST
        vm.expectRevert();
        SY.previewDeposit(INVALID_ADDRESS, AMOUNT_WSTETH_DEPOSIT);
    }

    function testPreviewRedeem() external {
        uint256 amountWstEth = SY.previewRedeem(wstEth, AMOUNT_SY_BURN);
        uint256 expectedAmountWstEth = AMOUNT_WSTETH_REDEEM;

        assertEq(amountWstEth, expectedAmountWstEth);

        // REVERT TEST
        vm.expectRevert();
        SY.previewRedeem(INVALID_ADDRESS, AMOUNT_WSTETH_DEPOSIT);
    }

    /*///////////////////////////////////////////////////////////////
                            MISC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function testYieldBearingToken() external view {
        address yieldToken = SY.yieldToken();
        address expectedYieldToken = wstEth;

        assertEq(yieldToken, expectedYieldToken);
    }

    function testGetTokensIn() external view {
        address tokenIn = SY.getTokensIn()[0];
        address expectedTokenIn = wstEth;

        assertEq(tokenIn, expectedTokenIn);
    }

    function testGetTokensOut() external view {
        address tokenOut = SY.getTokensOut()[0];
        address expectedTokenOut = wstEth;

        assertEq(tokenOut, expectedTokenOut);
    }

    function testIsValidTokeIn() external view {
        bool response1 = SY.isValidTokenIn(wstEth);
        bool expectedResponse1 = true;

        bool response2 = SY.isValidTokenIn(INVALID_ADDRESS);
        bool expectedResponse2 = false;

        assertEq(response1, expectedResponse1);
        assertEq(response2, expectedResponse2);
    }

    function testIsValidTokeOut() external view {
        bool response1 = SY.isValidTokenOut(wstEth);
        bool expectedResponse1 = true;

        bool response2 = SY.isValidTokenOut(INVALID_ADDRESS);
        bool expectedResponse2 = false;

        assertEq(response1, expectedResponse1);
        assertEq(response2, expectedResponse2);
    }

    function TestAssetInfo() external view {
        (, address assetAddress, uint8 assetDecimals) = SY.assetInfo();

        address expectedAssetAddress = wstEth;
        uint8 expectedAssetDecimals = IWstEth(wstEth).decimals();

        assertEq(assetAddress, expectedAssetAddress);
        assertEq(assetDecimals, expectedAssetDecimals);
    }
}
