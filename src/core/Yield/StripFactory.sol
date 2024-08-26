// SPDX-License-identifier; MIT
pragma solidity 0.8.24;

import {PrincipalToken} from "./PrincipalToken.sol";
import {YieldToken} from "./YieldToken.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "forge-std/console.sol";

contract StripFactory {
    function createPtYt(
        address sy,
        uint256 expiry,
        uint256 interestFee
    ) external {
        // PrincipalToken PT = new PrincipalToken();
    }

    function getSyMetadata(address sy) external view returns (string memory) {
        return IERC20Metadata(sy).symbol();
    }
}
