// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {TestYieldContracts} from "../../helpers/TestYieldContracts.sol";
import {console} from "forge-std/console.sol";
import {PMath} from "../../../lib/PMath.sol";
import "../../../script/DeployRouterYt.s.sol";
import {RouterYT} from "../../../src/router/RouterYT.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ISY} from "../../../src/interfaces/core/ISY.sol";
import {IYT} from "../../../src/interfaces/core/IYT.sol";
import {IPT} from "../../../src/interfaces/core/IPT.sol";

contract TestYTRouter is TestYieldContracts {
    using PMath for uint256;

    address private factory;

    RouterYT private routerYt;
    ISY private sy;
    IPT private pt;
    IYT private yt;

    uint256 private immutable EXPIRY = block.timestamp + (10 * DAY);
    uint256 private constant AMOUNT_SY = 1e18;

    function setUp() external {
        sy = ISY(_deploySYForTesting());

        (address PT, address YT, address _factory) = _createPtYt(
            address(sy),
            EXPIRY
        );

        DeployRouterYt deployer = new DeployRouterYt();
        routerYt = RouterYT(deployer.run());

        factory = _factory;
        yt = IYT(YT);
        pt = IPT(PT);
    }

    function testStrip() external prank(USER_0) {
        _mintWstEthForUser(sy.yieldToken(), USER_0, 1e18);

        IERC20(sy.yieldToken()).approve(address(routerYt), 1e18);
        routerYt.strip(address(sy), address(yt), sy.yieldToken(), 1e18);
    }
}
