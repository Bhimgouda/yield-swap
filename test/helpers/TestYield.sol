// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {TestBase} from "./TestBase.sol";
import {console} from "forge-std/console.sol";
import {PMath} from "../../lib/PMath.sol";

import {ISY} from "../../src/interfaces/core/ISY.sol";
import {IPtYtFactory} from "../../src/interfaces/core/IPtYtFactory.sol";
import {IYT} from "../../src/interfaces/core/IYT.sol";
import {IPT} from "../../src/interfaces/core/IPT.sol";
import {IYBT} from "../../src/interfaces/core/IYBT.sol";

import {DeploySYWstEth} from "../../script/SY/DeploySYWstEth.s.sol";
import {DeploySYCompound} from "../../script/SY/DeploySYCompound.s.sol";
import {DeploySYGlp} from "../../script/SY/DeploySYGlp.s.sol";

import {DeployPtYtFactory} from "../../script/DeployPtYtFactory.s.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract TestYield is TestBase {
    using PMath for uint256;

    uint256 internal constant AMOUNT_SY = 1e18;
    uint256 internal constant EXPIRY_DURATION = 365 days;

    address internal ybtUnderlying;
    IYBT internal YBT;
    ISY internal SY;
    IPtYtFactory internal ptYtFactory;
    IYT internal YT;
    IPT internal PT;

    function _yieldTestSetup() internal {
        _deploySYWstEth();
        _deployPtYtFactory();
        _createPtYt();
    }

    function _deploySYWstEth() internal {
        DeploySYWstEth deploySYWstEth = new DeploySYWstEth();
        SY = ISY(deploySYWstEth.run());

        YBT = IYBT(ISY(SY).yieldToken());
        (, ybtUnderlying, ) = ISY(SY).assetInfo();
    }

    function _deploySYCompound() internal {
        DeploySYCompound deploySYCompound = new DeploySYCompound();
        SY = ISY(deploySYCompound.run());

        YBT = IYBT(ISY(SY).yieldToken());
        (, ybtUnderlying, ) = ISY(SY).assetInfo();
    }

    function _deploySYGlp() internal {
        DeploySYGlp deploySYGlp = new DeploySYGlp();
        SY = ISY(deploySYGlp.run());

        YBT = IYBT(ISY(SY).yieldToken());
        (, ybtUnderlying, ) = ISY(SY).assetInfo();
    }

    function _deployPtYtFactory() internal {
        DeployPtYtFactory deployPtYtFactory = new DeployPtYtFactory();
        ptYtFactory = IPtYtFactory(deployPtYtFactory.run());
    }

    function _createPtYt() internal {
        (address _PT, address _YT) = IPtYtFactory(ptYtFactory).createPtYt(
            address(SY),
            EXPIRY_DURATION
        );

        PT = IPT(_PT);
        YT = IYT(_YT);
    }

    /**
     * @dev Adds interest to the YBT to increase the exchange rate
     */
    function _addInterest() internal {
        return YBT.addInterest();
    }
}
