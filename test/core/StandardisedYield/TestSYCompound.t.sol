// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {PMath} from "../../../lib/PMath.sol";
import {TestBase} from "../../helpers/TestBase.sol";
import {HelperConfig} from "../../../script/helpers/HelperConfig.s.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ICdai} from "../../../src/interfaces/Icore/ICdai.sol";

import {DeploySYCompound} from "../../../script/SY/DeploySYCompound.s.sol";
import {IStandardizedYieldToken} from "../../../src/interfaces/Icore/IStandardizedYieldToken.sol";

contract TestSYCompound is Test, TestBase {
    IStandardizedYieldToken private SY;

    // The Underlying Asset
    address private cdai;

    // As the underlying asset has 8 decimals and the SY mint is 1:1
    uint256 AMOUNT_CDAI_DEPOSIT = 100e8;
    uint256 AMOUNT_CDAI_REDEEM = 100e8;
    uint256 AMOUNT_SY_MINT = 100e18;
    uint256 AMOUNT_SY_BURN = 100e18;

    function setUp() external {
        HelperConfig helperConfig = new HelperConfig();
        cdai = helperConfig.getConfig().yieldBearingTokens[0];

        DeploySYCompound deploySYCompound = new DeploySYCompound();
        SY = IStandardizedYieldToken(deploySYCompound.run());
    }

    modifier deposited() {
        _mintCdaiForUser(cdai, USER, 100e18);
        IERC20(cdai).approve(address(SY), AMOUNT_CDAI_DEPOSIT);
        SY.deposit(USER, cdai, AMOUNT_CDAI_DEPOSIT, AMOUNT_SY_MINT);
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            SYBase FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function testDeposit() external prankUser {
        _mintCdaiForUser(cdai, USER, 100e18);

        // Arrange
        uint256 userCdaiStartBal = IERC20(cdai).balanceOf(USER);
        uint256 userSYStartBal = SY.balanceOf(USER);
        uint256 syCdaiStartBal = IERC20(cdai).balanceOf(address(SY));
        uint256 syStartTotalSupply = SY.totalSupply();

        // Act
        IERC20(cdai).approve(address(SY), AMOUNT_CDAI_DEPOSIT);
        SY.deposit(USER, cdai, AMOUNT_CDAI_DEPOSIT, AMOUNT_SY_MINT);

        // Assert
        uint256 userCdaiEndBal = IERC20(cdai).balanceOf(USER);
        uint256 userSYEndBal = SY.balanceOf(USER);
        uint256 syCdaiEndBal = IERC20(cdai).balanceOf(address(SY));
        uint256 syEndTotalSupply = SY.totalSupply();

        assertEq(userCdaiStartBal - userCdaiEndBal, AMOUNT_CDAI_DEPOSIT);
        assertEq(userSYEndBal - userSYStartBal, AMOUNT_SY_MINT);
        assertEq(syCdaiEndBal - syCdaiStartBal, AMOUNT_CDAI_DEPOSIT);
        assertEq(syEndTotalSupply - syStartTotalSupply, AMOUNT_SY_MINT);
    }

    function testRedeem() external prankUser deposited {
        // Arrange
        uint256 userCdaiStartBal = IERC20(cdai).balanceOf(USER);
        uint256 userSYStartBal = SY.balanceOf(USER);
        uint256 syCdaiStartBal = IERC20(cdai).balanceOf(address(SY));
        uint256 syStartTotalSupply = SY.totalSupply();

        // Act
        SY.redeem(USER, AMOUNT_SY_BURN, cdai, AMOUNT_CDAI_REDEEM, false);

        // Assert
        uint256 userCdaiEndBal = IERC20(cdai).balanceOf(USER);
        uint256 userSYEndBal = SY.balanceOf(USER);
        uint256 syCdaiEndBal = IERC20(cdai).balanceOf(address(SY));
        uint256 syEndTotalSupply = SY.totalSupply();

        assertEq(userCdaiEndBal - userCdaiStartBal, AMOUNT_CDAI_REDEEM);
        assertEq(userSYStartBal - userSYEndBal, AMOUNT_SY_BURN);
        assertEq(syCdaiStartBal - syCdaiEndBal, AMOUNT_CDAI_REDEEM);
        assertEq(syStartTotalSupply - syEndTotalSupply, AMOUNT_SY_BURN);
    }

    /*///////////////////////////////////////////////////////////////
                            PREVIEW RELATED FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    // NEED CLARITY
    function testExchangeRate() external view {
        uint256 exchangeRate = SY.exchangeRate();

        // cdai has 8 decimals + the value is scaled by 18
        // So we divide it by 1e8 to make it comply to our SY.exchangeRate()
        uint256 expectedExchangeRate = ICdai(cdai).exchangeRateStored() / 1e8;
        assertEq(exchangeRate, expectedExchangeRate);
    }

    /*///////////////////////////////////////////////////////////////
                            PREVIEW RELATED FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function testPreviewDeposit() external {
        uint256 amountSY = SY.previewDeposit(cdai, AMOUNT_CDAI_DEPOSIT);
        uint256 expectedAmountSY = AMOUNT_SY_MINT; // As SY Compound has 18 decimals

        assertEq(amountSY, expectedAmountSY);

        // REVERT TEST
        vm.expectRevert();
        SY.previewDeposit(INVALID_ADDRESS, AMOUNT_CDAI_DEPOSIT);
    }

    function testPreviewRedeem() external {
        uint256 amountCdai = SY.previewRedeem(cdai, AMOUNT_SY_BURN);
        uint256 expectedAmountCdai = AMOUNT_CDAI_REDEEM; // As SY Compound has 18 decimals

        assertEq(amountCdai, expectedAmountCdai);

        // REVERT TEST
        vm.expectRevert();
        SY.previewRedeem(INVALID_ADDRESS, AMOUNT_CDAI_DEPOSIT);
    }

    /*///////////////////////////////////////////////////////////////
                            MISC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function testYieldBearingToken() external view {
        address yieldToken = SY.yieldToken();
        address expectedYieldToken = cdai;

        assertEq(yieldToken, expectedYieldToken);
    }

    function testGetTokensIn() external view {
        address tokenIn = SY.getTokensIn()[0];
        address expectedTokenIn = cdai;

        assertEq(tokenIn, expectedTokenIn);
    }

    function testGetTokensOut() external view {
        address tokenOut = SY.getTokensOut()[0];
        address expectedTokenOut = cdai;

        assertEq(tokenOut, expectedTokenOut);
    }

    function testIsValidTokeIn() external view {
        bool response1 = SY.isValidTokenIn(cdai);
        bool expectedResponse1 = true;

        bool response2 = SY.isValidTokenIn(INVALID_ADDRESS);
        bool expectedResponse2 = false;

        assertEq(response1, expectedResponse1);
        assertEq(response2, expectedResponse2);
    }

    function testIsValidTokeOut() external view {
        bool response1 = SY.isValidTokenOut(cdai);
        bool expectedResponse1 = true;

        bool response2 = SY.isValidTokenOut(INVALID_ADDRESS);
        bool expectedResponse2 = false;

        assertEq(response1, expectedResponse1);
        assertEq(response2, expectedResponse2);
    }

    function TestAssetInfo() external view {
        (, address assetAddress, uint8 assetDecimals) = SY.assetInfo();

        address expectedAssetAddress = cdai;
        uint8 expectedAssetDecimals = ICdai(cdai).decimals();

        assertEq(assetAddress, expectedAssetAddress);
        assertEq(assetDecimals, expectedAssetDecimals);
    }
}
