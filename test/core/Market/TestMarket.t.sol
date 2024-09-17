// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.19;

// import {TestYield} from "../../helpers/TestYield.sol";
// import {console} from "forge-std/console.sol";
// import {PMath} from "../../../lib/PMath.sol";

// contract TestMarket is TestBase {
//     using PMath for uint256;

//     function _maTestSetup() internal {
//         SY = ISY(_deploySYCompound());

//         ptYtFactory = IPtYtFactory(_deployPtYtFactory());

//         (address _PT, address _YT) = _createPtYt(
//             address(ptYtFactory),
//             address(SY),
//             EXPIRY_DURATION
//         );
//         PT = IPT(_PT);
//         YT = IYT(_YT);
//     }
// }
