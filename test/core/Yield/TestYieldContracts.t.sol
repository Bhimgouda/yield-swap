// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.24;

// import {Test} from "forge-std/Test.sol";
// import {console} from "forge-std/console.sol";

// import {DeploySyCompound} from "../../../script/SY/DeploySYCompound.s.sol";

// import {DeployPtYtFactory} from "../../../script/DeployPtYtFactory.s.sol";
// import {IPtYtFactory} from "../../../src/interfaces/Icore/IPtYtFactory.sol";

// import {IYieldToken} from "../../../src/interfaces/Icore/IYieldToken.sol";
// import {IPrincipalToken} from "../../../src/interfaces/Icore/IPrincipalToken.sol";

// // These test uses

// contract TestYieldContracts is Test {
//     IPtYtFactory internal ptYtFactory;
//     IYieldToken private YT;
//     IPrincipalToken private PT;

//     // CONSTANTS
//     uint256 private constant INITEREST_FEE_RATE = 1e17;
//     address private immutable TREASURY = makeAddr("TREASURY");

//     function setUp() external {
//         DeployPtYtFactory deployPtYtFactory = new DeployPtYtFactory();
//         ptYtFactory = IPtYtFactory(
//             deployPtYtFactory.run(INITEREST_FEE_RATE, TREASURY)
//         );

//         DeploySyCompound deploySyCompound = new DeploySyCompound();
//         address syCompound = deploySyCompound.run();

//         (address pt, address yt) = ptYtFactory.createPtYt(
//             syCompound,
//             block.timestamp + (10 * 86400)
//         );

//         YT = IYieldToken(yt);
//         PT = IPrincipalToken(pt);
//     }
// }
