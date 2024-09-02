// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {TestBase} from "../../helpers/TestBase.sol";
import {console} from "forge-std/console.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IWstEth} from "../../../src/interfaces/core/IWstEth.sol";

import {DeploySYWstEth} from "../../../script/SY/DeploySYWstEth.sol";
import {ISY} from "../../../src/interfaces/core/ISY.sol";

contract TestSYWstEth is TestBase {
    ISY private sy;

    // The Underlying Asset
    address private wstEth;

    //sy mint is 1:1
    uint256 AMOUNT_WSTETH_DEPOSIT = 100e18;
    uint256 AMOUNT_WSTETH_REDEEM = 100e18;
    uint256 AMOUNT_SY_MINT = 100e18;
    uint256 AMOUNT_SY_BURN = 100e18;

    function setUp() external {
        DeploySYWstEth deploySYWstEth = new DeploySYWstEth();
        (address SY, address _wstEth) = deploySYWstEth.run();

        sy = ISY(SY);
        wstEth = _wstEth;
    }

    /*///////////////////////////////////////////////////////////////
                            PREVIEW RELATED FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    // NEED CLARITY
    function testExchangeRate() external view {
        uint256 exchangeRate = sy.exchangeRate();

        // So we divide it by 1e8 to make it comply to our sy.exchangeRate()
        uint256 expectedExchangeRate = IWstEth(wstEth).getStETHByWstETH(ONE);
        assertEq(exchangeRate, expectedExchangeRate);
    }

    /*///////////////////////////////////////////////////////////////
                            PREVIEW RELATED FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function testPreviewDeposit() external {
        uint256 amountSY = sy.previewDeposit(wstEth, AMOUNT_WSTETH_DEPOSIT);
        uint256 expectedamountSY = AMOUNT_SY_MINT;

        assertEq(amountSY, expectedamountSY);

        // REVERT TEST
        vm.expectRevert();
        sy.previewDeposit(INVALID_ADDRESS, AMOUNT_WSTETH_DEPOSIT);
    }

    function testPreviewRedeem() external {
        uint256 amountWstEth = sy.previewRedeem(wstEth, AMOUNT_SY_BURN);
        uint256 expectedAmountWstEth = AMOUNT_WSTETH_REDEEM;

        assertEq(amountWstEth, expectedAmountWstEth);

        // REVERT TEST
        vm.expectRevert();
        sy.previewRedeem(INVALID_ADDRESS, AMOUNT_WSTETH_DEPOSIT);
    }

    /*///////////////////////////////////////////////////////////////
                            MISC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function testYieldBearingToken() external view {
        address yieldToken = sy.yieldToken();
        address expectedYieldToken = wstEth;

        assertEq(yieldToken, expectedYieldToken);
    }

    function testGetTokensIn() external view {
        address tokenIn = sy.getTokensIn()[0];
        address expectedTokenIn = wstEth;

        assertEq(tokenIn, expectedTokenIn);
    }

    function testGetTokensOut() external view {
        address tokenOut = sy.getTokensOut()[0];
        address expectedTokenOut = wstEth;

        assertEq(tokenOut, expectedTokenOut);
    }

    function testIsValidTokeIn() external view {
        bool response1 = sy.isValidTokenIn(wstEth);
        bool expectedResponse1 = true;

        bool response2 = sy.isValidTokenIn(INVALID_ADDRESS);
        bool expectedResponse2 = false;

        assertEq(response1, expectedResponse1);
        assertEq(response2, expectedResponse2);
    }

    function testIsValidTokeOut() external view {
        bool response1 = sy.isValidTokenOut(wstEth);
        bool expectedResponse1 = true;

        bool response2 = sy.isValidTokenOut(INVALID_ADDRESS);
        bool expectedResponse2 = false;

        assertEq(response1, expectedResponse1);
        assertEq(response2, expectedResponse2);
    }

    function TestAssetInfo() external view {
        (, address assetAddress, uint8 assetDecimals) = sy.assetInfo();

        address expectedAssetAddress = wstEth;
        uint8 expectedAssetDecimals = IWstEth(wstEth).decimals();

        assertEq(assetAddress, expectedAssetAddress);
        assertEq(assetDecimals, expectedAssetDecimals);
    }
}
