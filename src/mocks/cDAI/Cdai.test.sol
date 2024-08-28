// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.24;

// import {Test, console} from "forge-std/Test.sol";
// import {ICdai} from "./interface/ICdai.sol";
// import {IDai} from "./interface/IDai.sol";
// import {DeployCdai} from "./script/DeployCdai.script.sol";
// import {DeployDai} from "./script/DeployDai.script.sol";

// contract TestCdai is Test {
//     IDai private Dai;
//     ICdai private Cdai;

//     address private USER = makeAddr("USER");
//     uint256 private constant USER_Dai_BALANCE = 1000e18;
//     uint256 private constant Dai_DEPOSIT_AMOUNT = 100e18;

//     address private INTEREST_MANAGER = makeAddr("INTEREST_MANAGER");
//     uint256 private constant MANAGER_Dai_BALANCE = 100000e18;
//     uint256 private constant INTEREST_AMOUNT = 100e18;

//     function setUp() external {
//         vm.startBroadcast();

//         DeployDai deployDai = new DeployDai();
//         address daiAddress = deployDai.run();
//         Dai = IDai(daiAddress);

//         DeployCdai deployCdai = new DeployCdai();
//         address cdaiAddress = deployCdai.run(daiAddress);
//         Cdai = ICdai(cdaiAddress);

//         Dai.mint(INTEREST_MANAGER, MANAGER_Dai_BALANCE);
//         Dai.mint(USER, USER_Dai_BALANCE);

//         vm.stopBroadcast();
//     }

//     //////////////////////
//     // Modifiers
//     /////////////////////

//     modifier prank(address prankAddress) {
//         vm.startPrank(prankAddress);
//         _;
//         vm.stopPrank();
//     }

//     //////////////////////
//     // Tests
//     /////////////////////

//     function testDepositWhenTotalSupplyIsZero() external {
//         // Act
//         _deposit(USER, Dai_DEPOSIT_AMOUNT);

//         // Assert
//         uint256 expectedCdaibalance = Dai_DEPOSIT_AMOUNT;
//         assertEq(Cdai.balanceOf(USER), expectedCdaibalance);
//     }

//     function testMultipleDeposits() external {
//         // Arrange
//         uint256 NUMBER_OF_DEPOSITS = 5;

//         // Act
//         for (uint256 i; i < NUMBER_OF_DEPOSITS; ++i) {
//             _deposit(USER, Dai_DEPOSIT_AMOUNT);
//         }

//         // Assert
//         uint256 expectedCdaiBalance = Dai_DEPOSIT_AMOUNT * 5;
//         assertEq(Cdai.balanceOf(USER), expectedCdaiBalance);
//     }

//     function testDepositAfterInterestAccrued() external {
//         // Arrange
//         _deposit(USER, Dai_DEPOSIT_AMOUNT);
//         _accrueInterest(INTEREST_AMOUNT);
//         uint256 startingCdaiBalance = Cdai.balanceOf(USER);

//         // Act
//         _deposit(USER, Dai_DEPOSIT_AMOUNT);

//         // Assert
//         uint256 expectedCdaiToBeMinted = (Dai_DEPOSIT_AMOUNT *
//             Cdai.totalSupply()) / Dai.balanceOf(address(Cdai));

//         uint256 endingCdaiBalance = startingCdaiBalance +
//             expectedCdaiToBeMinted;

//         assertEq(Cdai.balanceOf(USER), endingCdaiBalance);
//     }

//     function testExchangeRateStored() external {
//         // Arrange
//         _deposit(USER, Dai_DEPOSIT_AMOUNT);
//         _accrueInterest(INTEREST_AMOUNT);

//         // Assert
//         uint256 expectedExchangeRate = ((Dai_DEPOSIT_AMOUNT + INTEREST_AMOUNT) *
//             1e18) / Cdai.totalSupply();
//         assertEq(Cdai.exchangeRateStored(), expectedExchangeRate);
//     }

//     // function testWithdraw() external {
//     //     _deposit(USER, Dai_DEPOSIT_AMOUNT);
//     //     _accrueInterest(INTEREST_AMOUNT);
//     //     uint256 startingCdaiBalance = Cdai.balanceOf(USER);
//     //     uint256 startingDaiBalance = Dai.balanceOf(USER);

//     //     _withdraw(USER, startingCdaiBalance);

//     //     uint256 endingCdaiBalance = Cdai.balanceOf(USER);
//     //     uint256 endingDaiBalance = Dai.balanceOf(USER);
//     //     uint256 daiRedeemed = Cdai.exchangeRateStored() * startingCdaiBalance;

//     //     assertEq(endingCdaiBalance, 0);
//     //     assertEq(daiRedeemed, endingDaiBalance - startingDaiBalance);
//     // }

//     function testUnderlying() external view {
//         assertEq(Cdai.underlying(), address(Dai));
//     }

//     function testAccrualBlockNumber() external {
//         _deposit(USER, Dai_DEPOSIT_AMOUNT);
//         _accrueInterest(INTEREST_AMOUNT);

//         assertEq(Cdai.accrualBlockNumber(), block.number);
//     }

//     //////////////////////
//     // Internal Functions
//     /////////////////////

//     function _deposit(
//         address from,
//         uint256 amount
//     ) internal prank(from) returns (uint256 CdaiAmount) {
//         Dai.approve(address(Cdai), amount);
//         return Cdai.deposit(amount);
//     }

//     function _withdraw(
//         address from,
//         uint256 amount
//     ) internal prank(from) returns (uint256 daiAmount) {
//         return Cdai.withdraw(amount);
//     }

//     function _accrueInterest(
//         uint256 amount
//     ) internal prank(INTEREST_MANAGER) returns (uint256 currentExchangeRate) {
//         Dai.approve(address(Cdai), amount);
//         return Cdai.accrueInterest(amount);
//     }
// }
