// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {PMath} from "./math/PMath.sol";

library SYConvertor {
    using PMath for uint256;

    function syToAsset(
        uint256 exchangeRate,
        uint256 amountSy
    ) internal pure returns (uint256 amountAsset) {
        return amountSy.mulDown(exchangeRate);
    }

    function assetToSy(
        uint256 exchangeRate,
        uint256 amountAsset
    ) internal pure returns (uint256 amountSy) {
        return amountAsset.divDown(exchangeRate);
    }
}
