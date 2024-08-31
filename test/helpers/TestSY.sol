// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {HelperConfig} from "../../script/helpers/HelperConfig.s.sol";

import {ICdai} from "../../src/interfaces/core/ICdai.sol";
import {IWstEth} from "../../src/interfaces/core/IWstEth.sol";
import {TestBase} from "./TestBase.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TestSY is TestBase {
    function _getWstEth() internal returns (address) {
        HelperConfig helperConfig = new HelperConfig();
        return helperConfig.getConfig().yieldBearingTokens[1];
    }

    function _getCdai() internal returns (address) {
        HelperConfig helperConfig = new HelperConfig();
        return helperConfig.getConfig().yieldBearingTokens[0];
    }

    function _mintCdaiForUser(address cdai, address user, uint256 amountDai) internal {
        address dai = ICdai(cdai).underlying();

        // Minted DAI for the user
        deal(dai, user, amountDai, true);

        // Deposited DAI in compound for CDAI
        IERC20(dai).approve(cdai, amountDai);
        ICdai(cdai).mint(amountDai);
    }

    function _mintWstEthForUser(address wstEth, address user, uint256 amountWstEth) internal {
        // MinteD wstEth Directly
        deal(wstEth, user, amountWstEth, true);
    }
}
