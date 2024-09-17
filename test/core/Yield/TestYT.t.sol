// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {TestYield} from "../../helpers/TestYield.sol";
import {console} from "forge-std/console.sol";
import {PMath} from "../../../lib/PMath.sol";

contract TestYT is TestYield {
    using PMath for uint256;

    function setUp() external {
        _yieldTestSetup();
    }

    function testPreviewStripSy()
        public
        returns (uint256 amountPt, uint256 amountYt)
    {
        (amountPt, amountYt) = YT.previewStripSy(AMOUNT_SY);
        uint256 expectedAmountPt = AMOUNT_SY.mulDown(SY.exchangeRate());

        assertEq(amountPt, amountYt, "Unequal amounts of PT and YT");
        assertEq(amountPt, expectedAmountPt);
    }

    function testPreviewRedeemSy() external {
        (uint256 amountPt, ) = testPreviewStripSy();

        uint256 amountSy = YT.previewRedeemSy(amountPt);
        uint256 expectedAmountSy = AMOUNT_SY;

        assertEq(amountSy, expectedAmountSy);
    }

    function testPreviewRedeemSyBeforeExpiry() external {
        // Just a different approach with hardcoded values
        uint256 amountPt = 1e17; // 0.1 PT
        uint256 amountYt = 2e17; // 0.2 YT

        uint256 amountSy = YT.previewRedeemSyBeforeExpiry(amountPt, amountYt);
        uint256 expectedAmountSy = amountPt.divDown(SY.exchangeRate()); // As PT is min in our case

        assertEq(amountSy, expectedAmountSy);
    }

    function testStripSyAddsSyToReserve() external prank(USER_0) {
        uint256 startSyBalanceOfYt = SY.balanceOf(address(YT));

        // Act
        _stripSy(USER_0, AMOUNT_SY);

        uint256 endSYBalanceOfYT = SY.balanceOf(address(YT));
        uint256 updatedSyReserve = YT.syReserve();

        assertEq(endSYBalanceOfYT - startSyBalanceOfYt, AMOUNT_SY);
        assertEq(
            endSYBalanceOfYT,
            updatedSyReserve,
            "Failed to updated internal syReserve"
        );
    }

    function testStripSyMintsPtYtForUser() external prank(USER_0) {
        uint256 startPtBalanceOfUser = PT.balanceOf(USER_0);
        uint256 startYtBalanceOfUser = YT.balanceOf(USER_0);
        uint256 startPtTotalSupply = PT.totalSupply();
        uint256 startYtTotalSupply = YT.totalSupply();

        _stripSy(USER_0, AMOUNT_SY);

        uint256 endPtBalanceOfUser = PT.balanceOf(USER_0);
        uint256 endYtBalanceOfUser = YT.balanceOf(USER_0);
        uint256 endPtTotalSupply = PT.totalSupply();
        uint256 endYtTotalSupply = YT.totalSupply();

        (uint256 expectedAmountPt, uint256 expectedAmountYt) = YT
            .previewStripSy(AMOUNT_SY);

        assertEq(endPtBalanceOfUser - startPtBalanceOfUser, expectedAmountPt);
        assertEq(endYtBalanceOfUser - startYtBalanceOfUser, expectedAmountYt);
        assertEq(endPtTotalSupply - startPtTotalSupply, expectedAmountPt);
        assertEq(endYtTotalSupply - startYtTotalSupply, expectedAmountYt);
    }

    function testStripSyRevertsIfExpired() external prank(USER_0) {
        _afterExpiry();

        vm.expectRevert();
        YT.stripSy(USER_0, AMOUNT_SY);
    }

    function testRedeemSyTransfersSyToUser() external prank(USER_0) {
        // Arrange
        (uint256 amountPt, ) = _stripSy(USER_0, AMOUNT_SY);
        _afterExpiry();

        uint256 startSyBalanceOfYt = SY.balanceOf(address(YT));
        uint256 startSyBalanceOfUser = SY.balanceOf(USER_0);

        // Act
        YT.redeemSy(USER_0, amountPt);

        // Assert
        uint256 endSyBalanceOfYt = SY.balanceOf(address(YT));
        uint256 endSyBalanceOfUser = SY.balanceOf(USER_0);
        uint256 updatedSyReserve = YT.syReserve();

        assertEq(startSyBalanceOfYt - endSyBalanceOfYt, AMOUNT_SY);
        assertEq(endSyBalanceOfUser - startSyBalanceOfUser, AMOUNT_SY);
        assertEq(
            endSyBalanceOfYt,
            updatedSyReserve,
            "Failed to updated internal syReserve"
        );
    }

    function testRedeemSyBurnsPtYtOfUser() external prank(USER_0) {
        // Arrange
        (uint256 amountPt, ) = _stripSy(USER_0, AMOUNT_SY);
        _afterExpiry();

        uint256 startPtBalanceOfUser = PT.balanceOf(USER_0);
        uint256 startYtBalanceOfUser = YT.balanceOf(USER_0);
        uint256 startPtTotalSupply = PT.totalSupply();
        uint256 startYtTotalSupply = YT.totalSupply();

        // Act
        YT.redeemSy(USER_0, amountPt);

        uint256 endPtBalanceOfUser = PT.balanceOf(USER_0);
        uint256 endYtBalanceOfUser = YT.balanceOf(USER_0);
        uint256 endPtTotalSupply = PT.totalSupply();
        uint256 endYtTotalSupply = YT.totalSupply();

        assertEq(startPtBalanceOfUser - endPtBalanceOfUser, amountPt);
        assertEq(startYtBalanceOfUser - endYtBalanceOfUser, amountPt);
        assertEq(startPtTotalSupply - endPtTotalSupply, amountPt);
        assertEq(startYtTotalSupply - endYtTotalSupply, amountPt);
    }

    function testRedeemSyBeforeExpiryRedeemsAdjustedSy()
        external
        prank(USER_0)
    {
        (uint256 amountPt, uint256 _amountYt) = _stripSy(USER_0, AMOUNT_SY);
        uint256 amountYt = _amountYt / 2;

        uint256 startSyBalanceOfUser = SY.balanceOf(USER_0);

        YT.redeemSyBeforeExpiry(USER_0, amountPt, amountYt);

        uint256 endSyBalanceOfUser = SY.balanceOf(USER_0);
        uint256 expectedEndSyBalanceOfUser = amountYt.divDown(
            SY.exchangeRate()
        );

        assertEq(
            endSyBalanceOfUser - startSyBalanceOfUser,
            expectedEndSyBalanceOfUser
        );
    }

    function testRedeemSyRevertsIfNotExpired() external prank(USER_0) {
        // Arrange
        (uint256 amountPt, ) = _stripSy(USER_0, AMOUNT_SY);

        vm.expectRevert();
        YT.redeemSy(USER_0, amountPt);
    }

    function testRedeemSyBeforeExpiryRevertsIfExpired() external prank(USER_0) {
        // Arrange
        (uint256 amountPt, uint256 amountYt) = _stripSy(USER_0, AMOUNT_SY);

        _afterExpiry();
        vm.expectRevert();
        YT.redeemSyBeforeExpiry(USER_0, amountPt, amountYt);
    }

    function _stripSy(
        address user,
        uint256 amountSy
    ) internal returns (uint256 amountPt, uint256 amountYt) {
        _mintSYForUser(address(SY), USER_0, amountSy);
        SY.approve(address(YT), amountSy);
        (amountPt, amountYt) = YT.stripSy(user, amountSy);
    }

    function _afterExpiry() internal {
        vm.warp(EXPIRY_DURATION);
    }

    function testCurrentSyExchangeRateIsValid() external {
        uint256 currentSyExchangeRate = YT.currentSyExchangeRate();
        uint256 syExchangeRate = SY.exchangeRate();

        assert(currentSyExchangeRate >= syExchangeRate);
    }

    /*///////////////////////////////////////////////////////////////
                           TESTS for External-View Functions
    //////////////////////////////////////////////////////////////*/

    function testYTMetadata() external view {
        string memory ytName = YT.name();
        string memory ytSymbol = YT.symbol();

        string memory expectedYtName = "YT Lido wstETH";
        string memory expectedYtSymbol = "YT-wstETH";

        assertEq(ytName, expectedYtName);
        assertEq(ytSymbol, expectedYtSymbol);
    }

    function testPTForYT() external view {
        address ptForyt = YT.PT();
        address expectedPtForYt = address(PT);

        assertEq(ptForyt, expectedPtForYt);
    }

    function testSYForYT() external view {
        address syForYt = YT.SY();
        address expectedSyForYt = address(SY);

        assertEq(syForYt, expectedSyForYt);
    }

    function testYTExpiry() external view {
        uint256 ytExpiry = YT.expiry();
        uint256 expectedYtExpiry = EXPIRY_DURATION;

        assertEq(ytExpiry, expectedYtExpiry);
    }

    function testYTIsExpiredBeforeExpiry() external view {
        bool response = YT.isExpired();
        bool expectedResponse = false;

        assertEq(response, expectedResponse);
    }

    function testYTIsExpiredAfterExpiry() external {
        vm.warp(EXPIRY_DURATION);

        bool response = YT.isExpired();
        bool expectedResponse = true;

        assertEq(response, expectedResponse);
    }
}
