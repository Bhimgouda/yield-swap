// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

import "./MarketCallbackHelper.sol";
import "../core/libraries/TokenHelper.sol";
import "../../lib/PMath.sol";
import "../../lib/LogExpMath.sol";
import "../interfaces/core/IYT.sol";

import {console} from "forge-std/console.sol";

abstract contract MarketCallback is CallbackHelper {
    using PMath for int256;
    using PMath for uint256;

    function swapCallback(
        uint256 ptToAccount,
        uint256 syToAccount,
        bytes calldata data
    ) external {
        ActionType swapType = _getActionType(data);
        if (swapType == ActionType.SwapExactSyForYt) {
            _callbackSwapExactSyForYt(ptToAccount, syToAccount, data);
        } else if (swapType == ActionType.SwapYtForSy) {
            _callbackSwapYtForSy(ptToAccount, syToAccount, data);
        } else {
            assert(false);
        }
    }

    function _callbackSwapExactSyForYt(
        uint256 amountPtToRepay,
        uint256 amountSyBorrowed,
        bytes calldata data
    ) internal {
        (
            address receiver,
            address YT,
            uint256 amountSyIn
        ) = _decodeSwapExactSyForYt(data);

        (uint256 amountPtMinted, ) = IYT(YT).stripSy(
            msg.sender,
            receiver,
            amountSyBorrowed + amountSyIn
        );

        if (amountPtMinted < amountPtToRepay)
            revert("Slippage: INSUFFICIENT_PT_REPAY");
    }

    function _callbackSwapYtForSy(
        uint256 amountPtBorrowed,
        uint256 amountSyToRepay,
        bytes calldata data
    ) internal {
        (address receiver, address YT) = _decodeSwapYtForSy(data);
        address SY = IYT(YT).SY();

        uint256 amountSyRedeemed = IYT(YT).redeemSyBeforeExpiry(
            address(this),
            amountPtBorrowed,
            amountPtBorrowed
        );

        if (amountSyRedeemed < amountSyToRepay) {
            revert("Slippage: INSUFFICIENT_SY_REPAY");
        }

        IERC20(SY).transfer(receiver, amountSyRedeemed - amountSyToRepay);
        IERC20(SY).transfer(msg.sender, amountSyToRepay);
    }
}
