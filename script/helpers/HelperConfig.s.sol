// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

/**
 * @title Network Helper config
 * @author
 * @notice We will only use forks on anvil (local)
 */

contract HelperConfig is Script {
    uint256 private SEPOLIA_CHAIN_ID = 11155111;
    uint256 private FORK_CHAIN_ID = 31337;
    uint256 private MAINNET_CHAIN_ID = 1;

    struct NetworkConfig {
        YieldBearingToken[2] yieldBearingTokens;
    }

    struct YieldBearingToken {
        address token;
        address underlying;
    }

    function getConfig()
        external
        view
        returns (NetworkConfig memory networkConfig)
    {
        console.log("ChainId = ", block.chainid);

        if (block.chainid == FORK_CHAIN_ID) {
            networkConfig = getForkConfig();
        } else if (block.chainid == SEPOLIA_CHAIN_ID) {
            networkConfig = getSepoliaConfig();
        } else if (block.chainid == MAINNET_CHAIN_ID) {
            networkConfig = getEthMainnetConfig();
        }
    }

    function getSepoliaConfig() internal pure returns (NetworkConfig memory) {}

    function getEthMainnetConfig()
        internal
        pure
        returns (NetworkConfig memory)
    {}

    /*///////////////////////////////////////////////////////////////
                            FORK CONFIG
    //////////////////////////////////////////////////////////////*/

    function getForkConfig() internal pure returns (NetworkConfig memory) {
        return NetworkConfig({yieldBearingTokens: _getYieldBearingTokens()});
    }

    // Only cDai is the yield bearing token for now
    function _getYieldBearingTokens()
        internal
        pure
        returns (YieldBearingToken[2] memory yieldBearingTokens)
    {
        yieldBearingTokens[0] = _getCdai();
        yieldBearingTokens[1] = _getWstEth();
    }

    function _getCdai() internal pure returns (YieldBearingToken memory) {
        address DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        address CDAI = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;

        return YieldBearingToken({token: CDAI, underlying: DAI});
    }

    function _getWstEth() internal pure returns (YieldBearingToken memory) {
        address STETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
        address WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;

        return YieldBearingToken({token: WSTETH, underlying: STETH});
    }
}
