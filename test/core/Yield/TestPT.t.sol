// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {TestYield} from "../../helpers/TestYield.sol";
import {console} from "forge-std/console.sol";

contract TestPT is TestYield {
    function setUp() external {
        _yieldTestSetup();
    }

    /*///////////////////////////////////////////////////////////////
                           Tests for External-View Functions
    //////////////////////////////////////////////////////////////*/

    function testPTMetadata() external view {
        string memory ptName = PT.name();
        string memory ptSymbol = PT.symbol();

        // Might need to change the hardcoded values
        string memory expectedPtName = "PT Lido wstETH";
        string memory expectedPtSymbol = "PT-wstETH";

        assertEq(ptName, expectedPtName);
        assertEq(ptSymbol, expectedPtSymbol);
    }

    function testFactoryForPT() external view {
        address factoryForPt = PT.factory();
        address expectedFactoryForPt = address(ptYtFactory);

        assertEq(factoryForPt, expectedFactoryForPt);
    }

    function testYTForPT() external view {
        address ytForPt = PT.YT();
        address expectedYtForPt = address(YT);

        assertEq(ytForPt, expectedYtForPt);
    }

    function testSYForPT() external view {
        address syForPt = PT.SY();
        address expectedSyForPt = address(SY);

        assertEq(syForPt, expectedSyForPt);
    }

    function testExpiry() external view {
        uint256 ptExpiry = PT.expiry();
        uint256 expectedPtExpiry = EXPIRY_DURATION;

        assertEq(ptExpiry, expectedPtExpiry);
    }

    function testIsExpiredBeforeExpiry() external view {
        bool response = PT.isExpired();
        bool expectedResponse = false;

        assertEq(response, expectedResponse);
    }

    function testIsExpiredAfterExpiry() external {
        vm.warp(EXPIRY_DURATION);

        bool response = PT.isExpired();
        bool expectedResponse = true;

        assertEq(response, expectedResponse);
    }
}
