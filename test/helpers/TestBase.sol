// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {PMath} from "../../lib/PMath.sol";

contract TestBase is Test {
    using PMath for uint256;
    address internal USER = makeAddr("USER");

    address internal INVALID_ADDRESS = makeAddr("INVALID");
    uint256 internal ONE = 1e18;
    uint256 internal DAY = 86400;

    modifier prankUser() {
        vm.startPrank(USER);
        vm.deal(USER, 1000 ether);
        _;
        vm.stopPrank();
    }

    modifier prank(address addr) {
        vm.startPrank(addr);
        vm.deal(addr, 1000 ether);
        _;
        vm.stopPrank();
    }
}
