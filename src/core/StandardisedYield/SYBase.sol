//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// Deposit - Take ibToken and mint equivalent amount of shares
// Redeem - Burn the SY token for user and give out equivalent shares
// ClaimRewards -

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ISY} from "../../interfaces/core/ISY.sol";

abstract contract SYBase is ERC20, ISY {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function deposit(
        address receiver,
        address tokenIn,
        uint256 amountTokenToDeposit,
        uint256 minSharesOut
    ) external payable returns (uint256 amountSharesOut) {
        // Checks
        require(isValidTokenIn(tokenIn), "Invalid TokenIn");
        require(amountTokenToDeposit > 0, "Zero Deposit");

        // Tranfer Token In
        IERC20(tokenIn).transferFrom(
            msg.sender,
            address(this),
            amountTokenToDeposit
        );

        // Calculate Shares out
        amountSharesOut = _deposit(amountTokenToDeposit);
        require(minSharesOut >= amountSharesOut, "Insufficient Shares out");

        // Mint shares
        _mint(receiver, amountSharesOut);
        emit Deposit(
            msg.sender,
            receiver,
            tokenIn,
            amountTokenToDeposit,
            amountSharesOut
        );
    }

    function redeem(
        address receiver,
        uint256 amountSharesToRedeem,
        address tokenOut,
        uint256 minTokenOut,
        bool burnFromInternalBalance
    ) external returns (uint256 amountTokenOut) {
        // Checks
        require(isValidTokenOut(tokenOut), "Invalid TokenIn");
        require(amountSharesToRedeem > 0, "Zero shares");

        // Calc Amount Out
        amountTokenOut = _redeem(amountSharesToRedeem);
        require(minTokenOut >= amountTokenOut, "Insufficient Amount Out");

        // Transfer Token Out
        IERC20(tokenOut).transfer(receiver, amountTokenOut);

        _burn(msg.sender, amountSharesToRedeem);
        emit Redeem(
            msg.sender,
            receiver,
            tokenOut,
            amountSharesToRedeem,
            amountTokenOut
        );
    }

    function _deposit(
        uint256 amounTokenToDeposit
    ) internal view virtual returns (uint256 amountSharesOut);

    function _redeem(
        uint256 amountSharesToRedeeem
    ) internal view virtual returns (uint256 amountTokenOut);

    // Exchange rate

    function exchangeRate() external view virtual returns (uint256 res);

    // Basic View Functions

    function yieldToken() external view virtual returns (address);

    function getTokensIn() external view virtual returns (address[] memory res);

    function getTokensOut()
        external
        view
        virtual
        returns (address[] memory res);

    function isValidTokenIn(address token) public view virtual returns (bool);

    function isValidTokenOut(address token) public view virtual returns (bool);

    function previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) external view virtual returns (uint256 amountSharesOut);

    function previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    ) external view virtual returns (uint256 amountTokenOut) {}

    function assetInfo()
        external
        view
        virtual
        returns (
            AssetType assetType,
            address assetAddress,
            uint8 assetDecimals
        );

    // Reward Related

    function claimRewards(
        address user
    ) external virtual returns (uint256[] memory rewardAmounts);

    function accruedRewards(
        address user
    ) external view virtual returns (uint256[] memory rewardAmounts);

    function rewardIndexesCurrent()
        external
        virtual
        returns (uint256[] memory indexes);

    function rewardIndexesStored()
        external
        view
        virtual
        returns (uint256[] memory indexes);

    function getRewardTokens() external view virtual returns (address[] memory);
}
