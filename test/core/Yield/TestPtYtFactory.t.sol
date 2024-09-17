// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {TestYield} from "../../helpers/TestYield.sol";
import {IPtYtFactory} from "../../../src/interfaces/core/IPtYtFactory.sol";

import {console} from "forge-std/console.sol";

/**
 * @title TestYield
 * @author
 * @notice Using SYWstEth to test TestYield, For context SYWstEth is a GYGP Token with no rewards
 */
contract TestPtYtFactory is TestYield {
    function setUp() external {
        _yieldTestSetup();
    }

    /*///////////////////////////////////////////////////////////////
                            PT-YT FACTORY TESTS
    //////////////////////////////////////////////////////////////*/

    function testSetInterestFeeRateUpdatesInterestFeeRate()
        external
        prank(ptYtFactory.owner())
    {
        uint256 newInterestFeeRate = 12e16;
        ptYtFactory.setInterestFeeRate(newInterestFeeRate);
        assertEq(ptYtFactory.interestFeeRate(), newInterestFeeRate);
    }

    function testSetTreasuryUpdatesTreasury()
        external
        prank(ptYtFactory.owner())
    {
        address newTreasury = makeAddr("NEW TREASURY");
        ptYtFactory.setTreasury(newTreasury);
        assertEq(ptYtFactory.treasury(), newTreasury);
    }
}
