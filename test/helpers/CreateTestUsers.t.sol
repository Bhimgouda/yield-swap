// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {HelperConfig} from "../../script/helpers/HelperConfig.s.sol";
import {PMath} from "../../lib/PMath.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ICdai} from "../../src/interfaces/Icore/ICdai.sol";
import {IWstEth} from "../../src/interfaces/Icore/IWstEth.sol";

contract TestHelper is Test {
    using PMath for uint256;

    string[5] private USERS = ["USER1", "USER2", "USER3", "USER4", "USER5"];
    uint256 private constant USER_GAS = 1000 ether;

    /*///////////////////////////////////////////////////////////////
                            CREATE TEST USERS
    //////////////////////////////////////////////////////////////*/

    // /**
    //  *
    //  * @param yieldBearingToken Yield Bearing Token or Token[]
    //  * @dev This function gets test users with enough underlying and yield bearing token Balance
    //  */
    function setUp()
        external
        returns (
            address[5] memory users,
            HelperConfig.YieldBearingToken[2] memory yieldBearingTokens
        )
    {
        HelperConfig helperConfig = new HelperConfig();
        yieldBearingTokens = helperConfig.getConfig().yieldBearingTokens;

        for (uint256 i; i < USERS.length; ++i) {
            address user = makeAddr(USERS[i]);
            vm.deal(user, USER_GAS);

            vm.startPrank(user);

            _mintCdaiForUsers(user, yieldBearingTokens[0]);
            _mintWstEthForUsers(user, yieldBearingTokens[0]);

            vm.stopPrank();
            users[i] = user;
        }
    }

    function _mintCdaiForUsers(
        address user,
        HelperConfig.YieldBearingToken memory cdaiToken
    ) internal {
        address cdai = cdaiToken.token;
        address dai = cdaiToken.underlying;
        uint256 DAI_AMOUNT = 1000e18;

        // Minted DAI for the user
        deal(dai, user, DAI_AMOUNT, true);

        // Deposited DAI in compound for CDAI
        IERC20(dai).approve(cdai, DAI_AMOUNT);
        ICdai(cdai).mint(DAI_AMOUNT);
    }

    function _mintWstEthForUsers(
        address user,
        HelperConfig.YieldBearingToken memory wstEthToken
    ) internal {
        address wstEth = wstEthToken.token;
        address stEth = wstEthToken.underlying;
        uint256 WSTETH_AMOUNT = 2e18;

        // MinteD wstEth Directly
        deal(wstEth, user, WSTETH_AMOUNT, true);
    }

    function test() external {}
}
