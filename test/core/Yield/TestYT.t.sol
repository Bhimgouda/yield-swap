// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {TestYieldContracts} from "../../helpers/TestYieldContracts.sol";
import {console} from "forge-std/console.sol";

import {ISY} from "../../../src/interfaces/core/ISY.sol";
import {IYT} from "../../../src/interfaces/core/IYT.sol";
import {IPT} from "../../../src/interfaces/core/IPT.sol";

contract TestYT is TestYieldContracts {
    address private factory;

    ISY private sy;
    IPT private pt;
    IYT private yt;

    uint256 private immutable EXPIRY = block.timestamp + (10 * DAY);

    function setUp() external {
        sy = ISY(_deploySYForTesting());

        (address PT, address YT, address _factory) = _createPtYt(
            address(sy),
            EXPIRY
        );
        factory = _factory;
        yt = IYT(YT);
        pt = IPT(PT);
    }

    function testYTMetadata() external view {
        string memory ytName = yt.name();
        string memory ytSymbol = yt.symbol();

        string memory expectedYtName = "YT Lido wstETH";
        string memory expectedYtSymbol = "YT-wstETH";

        assertEq(ytName, expectedYtName);
        assertEq(ytSymbol, expectedYtSymbol);
    }

    function testPTForYT() external view {
        address ptForyt = yt.PT();
        address expectedPtForYt = address(pt);

        assertEq(ptForyt, expectedPtForYt);
    }

    function testSYForYT() external view {
        address syForYt = yt.SY();
        address expectedSyForYt = address(sy);

        assertEq(syForYt, expectedSyForYt);
    }

    function testYTExpiry() external view {
        uint256 ytExpiry = yt.expiry();
        uint256 expectedYtExpiry = EXPIRY;

        assertEq(ytExpiry, expectedYtExpiry);
    }

    function testYTIsExpiredBeforeExpiry() external view {
        bool response = yt.isExpired();
        bool expectedResponse = false;

        assertEq(response, expectedResponse);
    }

    function testYTIsExpiredAfterExpiry() external {
        vm.warp(EXPIRY);

        bool response = yt.isExpired();
        bool expectedResponse = true;

        assertEq(response, expectedResponse);
    }
}
