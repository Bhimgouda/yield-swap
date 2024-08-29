// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {HelperConfig} from "../../script/helpers/HelperConfig.s.sol";
import {PMath} from "../../lib/PMath.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ICdai} from "../../src/interfaces/Icore/ICdai.sol";
import {IWstEth} from "../../src/interfaces/Icore/IWstEth.sol";

contract TestBase is Test {
    // using PMath for uint256;
    // address[5] internal users;
    // address[2] internal yieldBearingTokens;

    address internal USER = makeAddr("USER");
    address internal INVALID_ADDRESS = makeAddr("INVALID");

    modifier prankUser() {
        vm.startPrank(USER);
        vm.deal(USER, 1000 ether);
        _;
        vm.stopPrank();
    }

    /*///////////////////////////////////////////////////////////////
                            CREATE TEST USERS
    //////////////////////////////////////////////////////////////*/
    // /**
    //  *
    //  * @param yieldBearingToken Yield Bearing Token or Token[]
    //  * @dev This function gets test users with enough underlying and yield bearing token Balance
    //  */
    // function initialize() internal {
    //     HelperConfig helperConfig = new HelperConfig();
    //     yieldBearingTokens = helperConfig.getConfig().yieldBearingTokens;
    //     string[5] memory USERS = ["USER1", "USER2", "USER3", "USER4", "USER5"];
    //     uint256 USER_GAS = 1000 ether;
    //     for (uint256 i; i < USERS.length; ++i) {
    //         address user = makeAddr(USERS[i]);
    //         vm.deal(user, USER_GAS);
    //         vm.startPrank(user);
    //         _mintCdaiForUsers(user, yieldBearingTokens[0]);
    //         _mintWstEthForUsers(user, yieldBearingTokens[0]);
    //         vm.stopPrank();
    //         users[i] = user;
    //     }
    // }

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

    // function _mintWstEthForUsers(address user, address wstEth) internal {
    //     uint256 WSTETH_AMOUNT = 2e18;
    //     // MinteD wstEth Directly
    //     deal(wstEth, user, WSTETH_AMOUNT, true);
    // }
}
