// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {HelperConfig} from "../../script/helpers/HelperConfig.s.sol";
import {PMath} from "../../lib/PMath.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ICdai} from "../../src/interfaces/core/ICdai.sol";
import {IWstEth} from "../../src/interfaces/core/IWstEth.sol";

contract TestBase is Test {
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

    function _mintCdaiForUser(
        address cdai,
        address user,
        uint256 amountDai
    ) internal {
        address dai = ICdai(cdai).underlying();

        // Minted DAI for the user
        deal(dai, user, amountDai, true);

        // Deposited DAI in compound for CDAI
        IERC20(dai).approve(cdai, amountDai);
        ICdai(cdai).mint(amountDai);
    }

    function _mintWstEthForUser(
        address wstEth,
        address user,
        uint256 amountWstEth
    ) internal {
        // MinteD wstEth Directly
        deal(wstEth, user, amountWstEth, true);
    }
}
