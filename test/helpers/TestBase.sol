// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {PMath} from "../../lib/PMath.sol";
import {console} from "forge-std/console.sol";

import {IYBT} from "../../src/interfaces/core/IYBT.sol";
import {ISY} from "../../src/interfaces/core/ISY.sol";

import {TokenDecimals} from "../../src/core/libraries/TokenDecimals.sol";

contract TestBase is Test {
    using PMath for uint256;
    using TokenDecimals for uint256;

    address internal immutable USER_0 = vm.envAddress("USER_0");
    address internal immutable USER_1 = vm.envAddress("USER_1");
    address internal immutable USER_2 = vm.envAddress("USER_2");

    address internal INVALID_ADDRESS = makeAddr("INVALID");
    uint256 internal ONE = 1e18;
    uint256 internal DAY = 86400;
    uint256 internal YEAR = DAY * 365;

    modifier prank(address addr) {
        if (addr.balance < 10 ether) vm.deal(addr, 1000 ether);
        vm.startPrank(addr);
        _;
        vm.stopPrank();
    }

    function _mintYbtForUser(
        address ybt,
        address user,
        uint256 amountYbt
    ) internal {
        IYBT(ybt).mint(amountYbt);
    }

    /**
     * @dev Works only for 1:1 (SY:YBT)
     */
    function _mintSYForUser(
        address SY,
        address user,
        uint256 amountSy
    ) internal {
        address YBT = ISY(SY).yieldToken();
        (, , uint8 ybtDecimals) = ISY(SY).assetInfo();
        uint256 amountYbt = amountSy.standardize(18, ybtDecimals);

        _mintYbtForUser(YBT, user, amountYbt);
        IYBT(YBT).approve(address(SY), amountYbt);

        ISY(SY).deposit(user, YBT, amountYbt, amountSy);
    }
}
