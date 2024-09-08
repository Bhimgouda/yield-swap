// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {TestBase} from "../../helpers/TestBase.sol";
import {console} from "forge-std/console.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ICdai} from "../../../src/interfaces/core/ICdai.sol";

import {DeploySYCompound} from "../../../script/SY/DeploySYCompound.s.sol";
import {ISY} from "../../../src/interfaces/core/Isy.sol";

contract TestSYCompound is TestBase {
    ISY private sy;

    // The Underlying Asset
    address private cdai;

    // As the underlying asset has 8 decimals and thesy mint is 1:1
    uint256 AMOUNT_CDAI_DEPOSIT = 100e8;
    uint256 AMOUNT_CDAI_REDEEM = 100e8;
    uint256 AMOUNT_SY_MINT = 100e18;
    uint256 AMOUNT_SY_BURN = 100e18;

    function setUp() external {
        DeploySYCompound deploySYCompound = new DeploySYCompound();
        address SY = deploySYCompound.run();

        sy = ISY(SY);
        cdai = ISY(SY).yieldToken();
    }

    /*///////////////////////////////////////////////////////////////
                            EXCHANGE-RATE FUNCTION
    //////////////////////////////////////////////////////////////*/

    // NEED CLARITY
    function testExchangeRate() external view {
        uint256 exchangeRate = sy.exchangeRate();

        // cdai has 8 decimals + the value is scaled by 18
        // So we divide it by 1e8 to make it comply to our sy.exchangeRate()
        uint256 expectedExchangeRate = ICdai(cdai).exchangeRateStored() / 1e8;
        assertEq(exchangeRate, expectedExchangeRate);
    }

    /*///////////////////////////////////////////////////////////////
                            PREVIEW RELATED FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function testPreviewDeposit() external {
        uint256 amountSY = sy.previewDeposit(cdai, AMOUNT_CDAI_DEPOSIT);
        uint256 expectedAmountSY = AMOUNT_SY_MINT; // As SY Compound has 18 decimals

        assertEq(amountSY, expectedAmountSY);

        // REVERT TEST
        vm.expectRevert();
        sy.previewDeposit(INVALID_ADDRESS, AMOUNT_CDAI_DEPOSIT);
    }

    function testPreviewRedeem() external {
        uint256 amountCdai = sy.previewRedeem(cdai, AMOUNT_SY_BURN);
        uint256 expectedAmountCdai = AMOUNT_CDAI_REDEEM; // As SY Compound has 18 decimals

        assertEq(amountCdai, expectedAmountCdai);

        // REVERT TEST
        vm.expectRevert();
        sy.previewRedeem(INVALID_ADDRESS, AMOUNT_CDAI_DEPOSIT);
    }

    /*///////////////////////////////////////////////////////////////
                            MISC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function testYieldBearingToken() external view {
        address yieldToken = sy.yieldToken();
        address expectedYieldToken = cdai;

        assertEq(yieldToken, expectedYieldToken);
    }

    function testGetTokensIn() external view {
        address tokenIn = sy.getTokensIn()[0];
        address expectedTokenIn = cdai;

        assertEq(tokenIn, expectedTokenIn);
    }

    function testGetTokensOut() external view {
        address tokenOut = sy.getTokensOut()[0];
        address expectedTokenOut = cdai;

        assertEq(tokenOut, expectedTokenOut);
    }

    function testIsValidTokeIn() external view {
        bool response1 = sy.isValidTokenIn(cdai);
        bool expectedResponse1 = true;

        bool response2 = sy.isValidTokenIn(INVALID_ADDRESS);
        bool expectedResponse2 = false;

        assertEq(response1, expectedResponse1);
        assertEq(response2, expectedResponse2);
    }

    function testIsValidTokeOut() external view {
        bool response1 = sy.isValidTokenOut(cdai);
        bool expectedResponse1 = true;

        bool response2 = sy.isValidTokenOut(INVALID_ADDRESS);
        bool expectedResponse2 = false;

        assertEq(response1, expectedResponse1);
        assertEq(response2, expectedResponse2);
    }

    function TestAssetInfo() external view {
        (, address assetAddress, uint8 assetDecimals) = sy.assetInfo();

        address expectedAssetAddress = cdai;
        uint8 expectedAssetDecimals = ICdai(cdai).decimals();

        assertEq(assetAddress, expectedAssetAddress);
        assertEq(assetDecimals, expectedAssetDecimals);
    }
}
