// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IPtYtFactory} from "../../interfaces/core/IPtYtFactory.sol";
import {IPT} from "../../interfaces/core/IPT.sol";

import {PMath} from "../libraries/math/PMath.sol";
import {LogExpMath} from "../libraries/math/LogExpMath.sol";

import {Market} from "./Market.sol";

contract MarketFactory {
    address private s_ptYtFactory;

    uint256 public immutable i_maxLnFeeRateRoot;
    uint256 public constant MIN_INITIAL_ANCHOR = PMath.ONE;

    address public treasury;
    uint256 public reserveFeePercent;

    // PT => scalarRoot => initialAnchor => lnFeeRateRoot => market
    mapping(address => mapping(uint256 => mapping(uint256 => mapping(uint256 => address))))
        private s_markets;
    address[] private s_allMarkets;

    constructor(
        address _ptYtFactory,
        address _treasury,
        uint256 _reserveFeePercent
    ) {
        s_ptYtFactory = _ptYtFactory;
        treasury = _treasury;
        reserveFeePercent = _reserveFeePercent;
        i_maxLnFeeRateRoot = uint256(
            LogExpMath.ln(int256((105 * PMath.IONE) / 100))
        );
    }

    /**
     * @notice Create a market between PT and its corresponding SY with scalar, anchor, feeRateRoot.
     * Anyone is allowed to create a market on their own.
     */
    function createNewMarket(
        address PT,
        uint256 scalarRoot,
        uint256 initialAnchor,
        uint256 lnFeeRateRoot
    ) external returns (address market) {
        IPtYtFactory ptYtFactory = IPtYtFactory(s_ptYtFactory);

        // Checks
        require(ptYtFactory.isPT(PT), "Not a PT");
        require(!IPT(PT).isExpired(), "PT is Expired");
        require(
            lnFeeRateRoot <= i_maxLnFeeRateRoot,
            "lnFeeRateRoot greater than i_maxLnFeeRateRoot"
        );
        require(
            initialAnchor >= MIN_INITIAL_ANCHOR,
            "Initial anchor less than MIN_INITIAL_ANCHOR"
        );
        require(
            s_markets[PT][scalarRoot][initialAnchor][lnFeeRateRoot] ==
                address(0),
            "Market already exists"
        );

        market = address(
            new Market(PT, scalarRoot, initialAnchor, lnFeeRateRoot)
        );

        s_markets[PT][scalarRoot][initialAnchor][lnFeeRateRoot] = market;
        s_allMarkets.push(market);
    }

    function PtYtFactory() external view returns (address) {
        return s_ptYtFactory;
    }
}
