// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {HelperConfig} from "../../script/helpers/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ICdai} from "../../src/interfaces/Icore/ICdai.sol";
import {PMath} from "../../lib/PMath.sol";

contract TestHelper is Test {
    using PMath for uint256;

    // Admin is required to add interest to the CDAI pool at intervals
    address private constant CDAI_ADMIN =
        0x6d903f6003cca6255D85CcA4D3B5E5146dC33925;
    uint256 private constant CDAI_ADMIN_BALANCE = 100000e18;
    uint256 private constant DAI_INTEREST_AMOUNT = 10000e18;

    string[5] private USERS = ["USER1", "USER2", "USER3", "USER4", "USER5"];
    uint256 private constant USER_GAS = 1000 ether;
    uint256 private constant DAI_AMOUNT = 1000e18;

    /*///////////////////////////////////////////////////////////////
                            CREATE TEST USERS
    //////////////////////////////////////////////////////////////*/

    // /**
    //  *
    //  * @param yieldBearingToken Yield Bearing Token or Token[]
    //  * @dev This function gets test users with enough underlying and yield bearing token Balance
    //  */
    function setUp() external returns (address[5] memory users, address admin) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.YieldBearingToken[1]
            memory yieldBearingTokens = helperConfig
                .getConfig()
                .yieldBearingTokens;

        address cdai = yieldBearingTokens[0].token;
        address dai = yieldBearingTokens[0].underlying;

        // Mint CDAI for Users

        for (uint256 i; i < USERS.length; ++i) {
            address user = makeAddr(USERS[i]);

            // Added gas balance
            vm.deal(user, USER_GAS);

            vm.startPrank(user);

            // Minted DAI for the user
            deal(dai, user, DAI_AMOUNT, true);

            // Deposited DAI in compound for CDAI
            IERC20(dai).approve(cdai, DAI_AMOUNT);
            ICdai(cdai).mint(DAI_AMOUNT);

            vm.stopPrank();

            users[i] = user;
            console.log(ICdai(cdai).exchangeRateStored());
        }

        // Add DAI interest to the CDAI Pool
        admin = CDAI_ADMIN;
        console.log(ICdai(cdai).exchangeRateStored());

        vm.startPrank(admin);
        vm.deal(admin, USER_GAS);
        deal(dai, admin, CDAI_ADMIN_BALANCE, true);

        console.log(ICdai(cdai).exchangeRateStored());

        IERC20(dai).approve(cdai, DAI_INTEREST_AMOUNT);
        ICdai(cdai)._addReserves(DAI_INTEREST_AMOUNT);
        ICdai(cdai).accrueInterest();
        console.log(ICdai(cdai).exchangeRateStored());

        vm.stopPrank();
    }

    function test() external {}
}
