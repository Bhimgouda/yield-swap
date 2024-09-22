// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

import {console} from "forge-std/console.sol";

abstract contract CallbackHelper {
    enum ActionType {
        SwapExactSyForYt,
        SwapYtForSy,
        SwapExactYtForPt,
        SwapExactPtForYt
    }

    /// ------------------------------------------------------------
    /// SwapExactSyForYt
    /// ------------------------------------------------------------

    function _encodeSwapExactSyForYt(
        address receiver,
        address YT,
        uint256 amountSyIn
    ) internal pure returns (bytes memory res) {
        res = new bytes(128); // Increase size to 128 bytes
        uint256 actionType = uint256(ActionType.SwapExactSyForYt);

        assembly {
            mstore(add(res, 32), actionType) // Store actionType at offset 32
            mstore(add(res, 64), receiver) // Store receiver at offset 64
            mstore(add(res, 96), YT) // Store YT at offset 96
            mstore(add(res, 128), amountSyIn) // Store amountSyIn at offset 128
        }
    }

    function _decodeSwapExactSyForYt(
        bytes calldata data
    ) internal pure returns (address receiver, address YT, uint256 amountSyIn) {
        assembly {
            // first 32 bytes is ActionType
            receiver := calldataload(add(data.offset, 32)) // Load receiver from offset 32
            YT := calldataload(add(data.offset, 64)) // Load YT from offset 64
            amountSyIn := calldataload(add(data.offset, 96)) // Load amountSyIn from offset 96
        }
    }

    /// ------------------------------------------------------------
    /// SwapYtForSy
    /// ------------------------------------------------------------

    function _encodeSwapYtForSy(
        address receiver,
        address YT
    ) internal pure returns (bytes memory res) {
        res = new bytes(96);
        uint256 actionType = uint256(ActionType.SwapYtForSy);

        assembly {
            mstore(add(res, 32), actionType)
            mstore(add(res, 64), receiver)
            mstore(add(res, 96), YT)
        }
    }

    function _decodeSwapYtForSy(
        bytes calldata data
    ) internal pure returns (address receiver, address YT) {
        assembly {
            // first 32 bytes is ActionType
            receiver := calldataload(add(data.offset, 32))
            YT := calldataload(add(data.offset, 64))
        }
    }

    /// ------------------------------------------------------------
    /// Misc functions
    /// ------------------------------------------------------------
    function _getActionType(
        bytes calldata data
    ) internal pure returns (ActionType actionType) {
        assembly {
            actionType := calldataload(data.offset)
        }
    }
}
