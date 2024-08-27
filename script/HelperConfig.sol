// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {DeployDai} from "../test/mocks/cDAI/script/DeployDai.script.sol";
import {DeployCdai} from "../test/mocks/cDAI/script/DeployCdai.script.sol";

interface IUnderlyingToken {
    function mint(address to, uint256 amount) external;

    function approve(address to, uint256 amount) external;
}

interface IYieldBearingToken {
    function deposit(uint256 amountDAI) external returns (uint256 amountCdai);

    function exchangeRateStored() external view returns (uint256);

    function accrueInterest(
        uint256 amountDAI
    ) external returns (uint256 currentExchangeRate);
}

contract HelperConfig is Script {
    uint256 private SEPOLIA_CHAIN_ID = 11155111;
    uint256 private ANVIL_CHAIN_ID = 31337;
    uint256 private MAINNET_CHAIN_ID = 1;
    YieldBearingToken[] private yieldBearingTokens;

    struct YieldBearingToken {
        address token;
        address underlying;
    }

    struct NetworkConfig {
        YieldBearingToken yieldBearingToken;
        address[5] users;
    }

    function getConfig() external returns (NetworkConfig memory networkConfig) {
        if (block.chainid == SEPOLIA_CHAIN_ID) {
            networkConfig = getSepoliaConfig();
        } else if (block.chainid == ANVIL_CHAIN_ID) {
            networkConfig = getOrCreateAnvilConfig();
        } else if (block.chainid == MAINNET_CHAIN_ID) {
            networkConfig = getEthMainnetConfig();
        }
    }

    function getOrCreateAnvilConfig()
        internal
        returns (NetworkConfig memory networkConfig)
    {
        YieldBearingToken memory yieldBearingToken = createYieldBearingToken();
        address[5] memory users = createTestUsers(yieldBearingToken);

        networkConfig = NetworkConfig({
            yieldBearingToken: yieldBearingToken,
            users: users
        });
    }

    function getSepoliaConfig() internal pure returns (NetworkConfig memory) {}

    function getEthMainnetConfig()
        internal
        pure
        returns (NetworkConfig memory)
    {}

    /////////// Internal ////////////

    // Only cDai is the yield bearing token for now
    function createYieldBearingToken()
        internal
        returns (YieldBearingToken memory)
    {
        vm.startBroadcast();
        DeployDai deployDai = new DeployDai();
        address daiAddress = deployDai.run();

        DeployCdai deployCdai = new DeployCdai();
        address cdaiAddress = deployCdai.run(daiAddress);
        vm.stopBroadcast();

        return YieldBearingToken({token: cdaiAddress, underlying: daiAddress});
    }

    /**
     *
     * @param yieldBearingToken Yield Bearing Token or Token[]
     * @dev This function creates test users with enough underlying and yield bearing token Balance
     */
    function createTestUsers(
        YieldBearingToken memory yieldBearingToken
    ) internal returns (address[5] memory users) {
        string[5] memory userNames = [
            "USER1",
            "USER2",
            "USER3",
            "USER4",
            "USER5"
        ];
        for (uint256 i; i < userNames.length; ++i) {
            address user = makeAddr(userNames[i]);
            vm.deal(user, 1000 ether);
            uint256 UNDERLYING_TOKEN_AMOUNT = 100000e18;
            uint256 DEPOSIT_AMOUNT = 1000e18;

            vm.startPrank(user);
            IUnderlyingToken(yieldBearingToken.underlying).mint(
                user,
                UNDERLYING_TOKEN_AMOUNT
            );
            IUnderlyingToken(yieldBearingToken.underlying).approve(
                yieldBearingToken.token,
                UNDERLYING_TOKEN_AMOUNT
            );
            IYieldBearingToken(yieldBearingToken.token).deposit(DEPOSIT_AMOUNT);

            if (i == users.length - 1) {
                // Interest Accrued
                uint256 INTEREST_AMOUNT = 1000e18;
                IYieldBearingToken(yieldBearingToken.token).accrueInterest(
                    INTEREST_AMOUNT
                );
            }

            vm.stopPrank();

            users[i] = user;
        }
    }
}
