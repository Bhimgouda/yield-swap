// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {PMath} from "../../lib/PMath.sol";
import {console} from "forge-std/console.sol";

import {ICdai} from "../../src/interfaces/core/ICdai.sol";
import {IWstEth} from "../../src/interfaces/core/IWstEth.sol";
import {IStEth} from "../../src/interfaces/core/IStEth.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TestBase is Test {
    using PMath for uint256;

    address internal immutable USER_0 = vm.envAddress("USER_0");
    address internal immutable USER_1 = vm.envAddress("USER_1");
    address internal immutable USER_2 = vm.envAddress("USER_2");

    address internal INVALID_ADDRESS = makeAddr("INVALID");
    uint256 internal ONE = 1e18;
    uint256 internal DAY = 86400;

    modifier prank(address addr) {
        if (addr.balance < 10 ether) vm.deal(addr, 1000 ether);
        vm.startPrank(addr);
        _;
        vm.stopPrank();
    }

    function _mintCdaiForUser(
        address cdai,
        address user,
        uint256 amountCdai
    ) internal {
        uint256 requiredDai = amountCdai.mulDown(
            ICdai(cdai).exchangeRateStored() / 1e18
        );
        if (block.chainid == 31337) {
            ICdai(cdai).mint(requiredDai);
        } else {
            address dai = ICdai(cdai).underlying();

            // Minted DAI for the user
            deal(dai, user, requiredDai, true);
            // Deposited DAI in compound for CDAI
            IERC20(dai).approve(cdai, requiredDai);
            ICdai(cdai).mint(requiredDai);
        }
    }

    // Deposits eth -> stEth -> wstEth
    function _mintWstEthForUser(
        address wstEth,
        address user,
        uint256 amountWstEth
    ) internal {
        uint256 requiredEth;

        if (block.chainid == 31337) {
            requiredEth = amountWstEth.mulDown(
                IWstEth(wstEth).getStETHByWstETH(1e18)
            );

            IWstEth(wstEth).wrap(requiredEth);
        } else {
            address stEth = IWstEth(wstEth).stETH();
            requiredEth = amountWstEth.mulDown(
                IWstEth(wstEth).getStETHByWstETH(1e18) + 1
            );
            deal(stEth, user, requiredEth, true);
            IERC20(stEth).approve(wstEth, requiredEth);
            IWstEth(wstEth).wrap(requiredEth);
        }
    }
}
