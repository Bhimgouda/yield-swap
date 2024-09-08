// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

// Mocks
import {StEth} from "../../src/mocks/StEth.mock.sol";
import {WstEth} from "../../src/mocks/WstEth.mock.sol";
import {DAI} from "../../src/mocks/Dai.mock.sol";
import {Cdai} from "../../src/mocks/Cdai.mock.sol";

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
        address[] yieldBearingTokens;
    }

    function run() external returns (NetworkConfig memory networkConfig) {
        if (block.chainid == MAINNET_FORK_CHAIN_ID) {
            networkConfig = getMainnetForkConfig();
        } else if (block.chainid == SEPOLIA_CHAIN_ID) {
            networkConfig = getSepoliaConfig();
        } else if (block.chainid == MAINNET_CHAIN_ID) {
            networkConfig = getEthMainnetConfig();
        } else if (block.chainid == LOCAL) {
            networkConfig = getLocalConfig();
        }
    }

    function getSepoliaConfig() internal pure returns (NetworkConfig memory) {}

    function getEthMainnetConfig()
        internal
        pure
        returns (NetworkConfig memory)
    {}

    /*///////////////////////////////////////////////////////////////
                            LOCAL CONFIG
    //////////////////////////////////////////////////////////////*/

    function getLocalConfig() internal returns (NetworkConfig memory) {
        address[] memory yieldBearingTokens = new address[](2);

        vm.startBroadcast();

        StEth stEth = new StEth();
        WstEth wstEth = new WstEth(address(stEth));

        DAI dai = new DAI();
        Cdai cdai = new Cdai(address(dai));

        vm.stopBroadcast();

        yieldBearingTokens[0] = address(cdai);
        yieldBearingTokens[1] = address(wstEth);

        return NetworkConfig({yieldBearingTokens: yieldBearingTokens});
    }

    /*///////////////////////////////////////////////////////////////
                            FORK CONFIG
    //////////////////////////////////////////////////////////////*/

    function getMainnetForkConfig()
        internal
        pure
        returns (NetworkConfig memory)
    {
        address[] memory yieldBearingTokens = new address[](2);
        yieldBearingTokens[0] = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
        yieldBearingTokens[1] = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;

        return NetworkConfig({yieldBearingTokens: yieldBearingTokens});
    }
}
