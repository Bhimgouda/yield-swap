// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {TestBase} from "../../helpers/TestBase.sol";
import {console} from "forge-std/console.sol";

import {DeploySYWstEth} from "../../../script/SY/DeploySYWstEth.sol";
import {ISY} from "../../../src/interfaces/core/ISY.sol";

import {DeployPtYtFactory} from "../../../script/DeployPtYtFactory.s.sol";
import {IPtYtFactory} from "../../../src/interfaces/core/IPtYtFactory.sol";

import {IYieldToken} from "../../../src/interfaces/core/IYieldToken.sol";
import {IPT} from "../../../src/interfaces/core/IPT.sol";

/**
 * @title TestYieldContracts
 * @author
 * @notice Using SYWstEth to test TestYieldContracts, For context SYWstEth is a GYGP Token with no rewards
 */

contract TestYieldContracts is Test, TestBase {
    address private FACTORY_OWNER = makeAddr("FACTORY_OWNER");
    IPtYtFactory internal ptYtFactory;

    ISY private SY;
    uint256 EXPIRY = block.timestamp + (10 * DAY);

    IYieldToken private YT;
    IPT private PT;

    // CONSTANTS
    uint256 private constant INTEREST_FEE_RATE = 1e17;
    address private immutable TREASURY = makeAddr("TREASURY");

    function setUp() external {
        // Deploy a SY Token for tests
        DeploySYWstEth deploySYWstEth = new DeploySYWstEth();
        SY = ISY(deploySYWstEth.run());

        // Deploy PtYtFactory
        DeployPtYtFactory deployPtYtFactory = new DeployPtYtFactory();
        ptYtFactory = IPtYtFactory(
            deployPtYtFactory.run(INTEREST_FEE_RATE, TREASURY)
        );

        FACTORY_OWNER = ptYtFactory.owner();

        // Create a Yield Stripping Pool for the SY
        (address pt, address yt) = ptYtFactory.createPtYt(address(SY), EXPIRY);

        YT = IYieldToken(yt);
        PT = IPT(pt);
    }

    /*///////////////////////////////////////////////////////////////
                            PT-YT FACTORY TESTS
    //////////////////////////////////////////////////////////////*/

    // Constructor Tests //

    function testGetInterestFeeRate() external view {
        uint256 interestFeeRate = ptYtFactory.getInterestFeeRate();
        uint256 expectedInterestFeeRate = INTEREST_FEE_RATE;

        assertEq(interestFeeRate, expectedInterestFeeRate);
    }

    function testGetTreasury() external view {
        address treasury = ptYtFactory.getTreasury();
        address expectedTreasury = TREASURY;

        assertEq(treasury, expectedTreasury);
    }

    function testSetInterestFeeRateUpdatesInterestFeeRate()
        external
        prank(FACTORY_OWNER)
    {
        uint256 newInterestFeeRate = INTEREST_FEE_RATE + 10;
        ptYtFactory.setInterestFeeRate(newInterestFeeRate);
        assertEq(ptYtFactory.getInterestFeeRate(), newInterestFeeRate);
    }

    function testSetTreasuryUpdatesTreasury() external prank(FACTORY_OWNER) {
        address newTreasury = makeAddr("NEW TREASURY");
        ptYtFactory.setTreasury(newTreasury);
        assertEq(ptYtFactory.getTreasury(), newTreasury);
    }

    /*///////////////////////////////////////////////////////////////
                            PT TESTS
    //////////////////////////////////////////////////////////////*/

    function testPTMetadata() external view {
        string memory ptName = PT.name();
        string memory ptSymbol = PT.symbol();

        string memory expectedPtName = "PT Lido wstETH";
        string memory expectedPtSymbol = "PT-wstETH";

        assertEq(ptName, expectedPtName);
        assertEq(ptSymbol, expectedPtSymbol);
    }

    function testFactoryForPT() external view {
        address factoryForPt = PT.getFactory();
        address expectedFactoryForPt = address(ptYtFactory);

        assertEq(factoryForPt, expectedFactoryForPt);
    }

    function testYTForPT() external view {
        address ytForPt = PT.getYT();
        address expectedYtForPt = address(YT);

        assertEq(ytForPt, expectedYtForPt);
    }

    function testSYForPT() external view {
        address syForPt = PT.getSY();
        address expectedSyForPt = address(SY);

        assertEq(syForPt, expectedSyForPt);
    }

    function testPTExpiry() external view {
        uint256 ptExpiry = PT.getExpiry();
        uint256 expectedPtExpiry = EXPIRY;

        assertEq(ptExpiry, expectedPtExpiry);
    }

    function testIsExpiredBeforeExpiry() external view {
        bool response = PT.isExpired();
        bool expectedResponse = false;

        assertEq(response, expectedResponse);
    }

    function testIsExpiredAfterExpiry() external {
        vm.warp(EXPIRY);

        bool response = PT.isExpired();
        bool expectedResponse = true;

        assertEq(response, expectedResponse);
    }

    /*///////////////////////////////////////////////////////////////
                            YT TESTS
    //////////////////////////////////////////////////////////////*/

    function testYTMetadata() external view {
        string memory ytName = YT.name();
        string memory ytSymbol = YT.symbol();

        string memory expectedYtName = "YT Lido wstETH";
        string memory expectedYtSymbol = "YT-wstETH";

        assertEq(ytName, expectedYtName);
        assertEq(ytSymbol, expectedYtSymbol);
    }

    function testPTForYT() external view {
        address ptForyt = YT.getPT();
        address expectedPtForYt = address(PT);

        assertEq(ptForyt, expectedPtForYt);
    }

    function testSYForPT() external view {
        address syForYt = YT.getSY();
        address expectedSyForPt = address(SY);

        assertEq(syForPt, expectedSyForPt);
    }

    function testPTExpiry() external view {
        uint256 ptExpiry = YT.getExpiry();
        uint256 expectedPtExpiry = EXPIRY;

        assertEq(ptExpiry, expectedPtExpiry);
    }

    function testIsExpiredBeforeExpiry() external view {
        bool response = YT.isExpired();
        bool expectedResponse = true;

        assertEq(response, expectedResponse);
    }

    function testIsExpiredAfterExpiry() external {
        vm.warp(EXPIRY);

        bool response = YT.isExpired();
        bool expectedResponse = false;

        assertEq(response, expectedResponse);
    }

    /*///////////////////////////////////////////////////////////////
                            YT-INTEREST-MANAGER TESTS
    //////////////////////////////////////////////////////////////*/
}
