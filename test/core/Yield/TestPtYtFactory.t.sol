// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {TestYieldContracts} from "../../helpers/TestYieldContracts.sol";
import {console} from "forge-std/console.sol";

import {ISY} from "../../../src/interfaces/core/ISY.sol";
import {IPtYtFactory} from "../../../src/interfaces/core/IPtYtFactory.sol";

import {IYT} from "../../../src/interfaces/core/IYT.sol";
import {IPT} from "../../../src/interfaces/core/IPT.sol";

/**
 * @title TestYieldContracts
 * @author
 * @notice Using SYWstEth to test TestYieldContracts, For context SYWstEth is a GYGP Token with no rewards
 */
contract TestPtYtFactory is TestYieldContracts {
    IPtYtFactory private ptYtFactory;
    address private FACTORY_OWNER;

    function setUp() external {
        FACTORY_OWNER = ptYtFactory.owner();
    }

    /*///////////////////////////////////////////////////////////////
                            PT-YT FACTORY TESTS
    //////////////////////////////////////////////////////////////*/

    function testSetInterestFeeRateUpdatesInterestFeeRate() external prank(FACTORY_OWNER) {
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
                    Tests for External-View Functions
    //////////////////////////////////////////////////////////////*/

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
}
