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
    uint256 private MAINNET_CHAIN_ID = 1;
    uint256 private MAINNET_FORK_CHAIN_ID = 2;
    uint256 private LOCAL = 31337;

    struct NetworkConfig {
        address[2] yieldBearingTokens;
    }

    function getConfig() external view returns (NetworkConfig memory networkConfig) {
        if (block.chainid == MAINNET_FORK_CHAIN_ID) {
            networkConfig = getMainnetForkConfig();
        } else if (block.chainid == SEPOLIA_CHAIN_ID) {
            networkConfig = getSepoliaConfig();
        } else if (block.chainid == MAINNET_CHAIN_ID) {
            networkConfig = getEthMainnetConfig();
        }
    }

    function getSepoliaConfig() internal pure returns (NetworkConfig memory) {}

    function getEthMainnetConfig() internal pure returns (NetworkConfig memory) {}

    /*///////////////////////////////////////////////////////////////
                            FORK CONFIG
    //////////////////////////////////////////////////////////////*/

    function getMainnetForkConfig() internal pure returns (NetworkConfig memory) {
        return NetworkConfig({yieldBearingTokens: _getYieldBearingTokens()});
    }

    // Only cDai is the yield bearing token for now
    function _getYieldBearingTokens() internal pure returns (address[2] memory yieldBearingTokens) {
        yieldBearingTokens[0] = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
        yieldBearingTokens[1] = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    }
}
