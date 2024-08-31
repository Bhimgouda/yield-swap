// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {TestYieldContracts} from "../../helpers/TestYieldContracts.sol";
import {console} from "forge-std/console.sol";

import {ISY} from "../../../src/interfaces/core/ISY.sol";

import {IYT} from "../../../src/interfaces/core/IYT.sol";
import {IPT} from "../../../src/interfaces/core/IPT.sol";

contract TestPT is TestYieldContracts {
    address private SY;
    address private factory;
    address private YT;

    IPT private pt;

    uint256 private immutable EXPIRY = block.timestamp + (10 * DAY);

    function setUp() external {
        SY = _deploySYForTesting();

        (address PT, address _YT, address _factory) = _createPtYt(SY, EXPIRY);
        factory = _factory;
        YT = _YT;
        pt = IPT(PT);
    }

    /*///////////////////////////////////////////////////////////////
                           Tests for External-View Functions
    //////////////////////////////////////////////////////////////*/

    function testPTMetadata() external view {
        string memory ptName = pt.name();
        string memory ptSymbol = pt.symbol();

        // Might need to change the hardcoded values
        string memory expectedPtName = "PT Lido wstETH";
        string memory expectedPtSymbol = "PT-wstETH";

        assertEq(ptName, expectedPtName);
        assertEq(ptSymbol, expectedPtSymbol);
    }

    function testFactoryForPT() external view {
        address factoryForPt = pt.factory();
        address expectedFactoryForPt = factory;

        assertEq(factoryForPt, expectedFactoryForPt);
    }

    function testYTForPT() external view {
        address ytForPt = pt.YT();
        address expectedYtForPt = YT;

        assertEq(ytForPt, expectedYtForPt);
    }

    function testSYForPT() external view {
        address syForPt = pt.SY();
        address expectedSyForPt = SY;

        assertEq(syForPt, expectedSyForPt);
    }

    function testExpiry() external view {
        uint256 ptExpiry = pt.expiry();
        uint256 expectedPtExpiry = EXPIRY;

        assertEq(ptExpiry, expectedPtExpiry);
    }

    function testIsExpiredBeforeExpiry() external view {
        bool response = pt.isExpired();
        bool expectedResponse = false;

        assertEq(response, expectedResponse);
    }

    function testIsExpiredAfterExpiry() external {
        vm.warp(EXPIRY);

        bool response = pt.isExpired();
        bool expectedResponse = true;

        assertEq(response, expectedResponse);
    }
}
