// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {TestYieldContracts} from "../../helpers/TestYieldContracts.sol";
import {console} from "forge-std/console.sol";
import {PMath} from "../../../lib/PMath.sol";

import {ISY} from "../../../src/interfaces/core/ISY.sol";
import {IYT} from "../../../src/interfaces/core/IYT.sol";
import {IPT} from "../../../src/interfaces/core/IPT.sol";

contract TestYT is TestYieldContracts {
    using PMath for uint256;

    address private factory;

    ISY private sy;
    IPT private pt;
    IYT private yt;

    uint256 private immutable EXPIRY = block.timestamp + (10 * DAY);
    uint256 private constant AMOUNT_SY = 1e18;

    function setUp() external {
        sy = ISY(_deploySYForTesting());

        (address PT, address YT, address _factory) = _createPtYt(address(sy), EXPIRY);
        factory = _factory;
        yt = IYT(YT);
        pt = IPT(PT);
    }

    function testPreviewStripSy() public returns (uint256 amountPt, uint256 amountYt) {
        (amountPt, amountYt) = yt.previewStripSy(AMOUNT_SY);
        uint256 expectedAmountPt = AMOUNT_SY.mulDown(sy.exchangeRate());

        assertEq(amountPt, amountYt, "Unequal amounts of PT and YT");
        assertEq(amountPt, expectedAmountPt);
    }

    function testPreviewRedeemSy() external {
        (uint256 amountPt,) = testPreviewStripSy();

        uint256 amountSy = yt.previewRedeemSy(amountPt);
        uint256 expectedAmountSy = AMOUNT_SY;

        assertEq(amountSy, expectedAmountSy);
    }

    function testPreviewRedeemSyBeforeExpiry() external {
        // Just a different approach with hardcoded values
        uint256 amountPt = 1e17; // 0.1 PT
        uint256 amountYt = 2e17; // 0.2 YT

        uint256 amountSy = yt.previewRedeemSyBeforeExpiry(amountPt, amountYt);
        uint256 expectedAmountSy = amountPt.divDown(sy.exchangeRate()); // As PT is min in our case

        assertEq(amountSy, expectedAmountSy);
    }

    function testStripSyAddsSyToReserve() external prank(USER) {
        uint256 startSyBalanceOfYt = sy.balanceOf(address(yt));

        // Act
        _stripSy(USER, AMOUNT_SY);

        uint256 endSYBalanceOfYT = sy.balanceOf(address(yt));
        uint256 updatedSyReserve = yt.syReserve();

        assertEq(endSYBalanceOfYT - startSyBalanceOfYt, AMOUNT_SY);
        assertEq(endSYBalanceOfYT, updatedSyReserve, "Failed to updated internal syReserve");
    }

    function testStripSyMintsPtYtForUser() external prank(USER) {
        uint256 startPtBalanceOfUser = pt.balanceOf(USER);
        uint256 startYtBalanceOfUser = yt.balanceOf(USER);
        uint256 startPtTotalSupply = pt.totalSupply();
        uint256 startYtTotalSupply = yt.totalSupply();

        _stripSy(USER, AMOUNT_SY);

        uint256 endPtBalanceOfUser = pt.balanceOf(USER);
        uint256 endYtBalanceOfUser = yt.balanceOf(USER);
        uint256 endPtTotalSupply = pt.totalSupply();
        uint256 endYtTotalSupply = yt.totalSupply();

        (uint256 expectedAmountPt, uint256 expectedAmountYt) = yt.previewStripSy(AMOUNT_SY);

        assertEq(endPtBalanceOfUser - startPtBalanceOfUser, expectedAmountPt);
        assertEq(endYtBalanceOfUser - startYtBalanceOfUser, expectedAmountYt);
        assertEq(endPtTotalSupply - startPtTotalSupply, expectedAmountPt);
        assertEq(endYtTotalSupply - startYtTotalSupply, expectedAmountYt);
    }

    function testStripSyRevertsIfExpired() external prank(USER) {
        _afterExpiry();

        vm.expectRevert();
        yt.stripSy(USER, AMOUNT_SY);
    }

    function testRedeemSyTransfersSyToUser() external prank(USER) {
        // Arrange
        (uint256 amountPt,) = _stripSy(USER, AMOUNT_SY);
        _afterExpiry();

        uint256 startSyBalanceOfYt = sy.balanceOf(address(yt));
        uint256 startSyBalanceOfUser = sy.balanceOf(USER);

        // Act
        yt.redeemSy(USER, amountPt);

        // Assert
        uint256 endSyBalanceOfYt = sy.balanceOf(address(yt));
        uint256 endSyBalanceOfUser = sy.balanceOf(USER);
        uint256 updatedSyReserve = yt.syReserve();

        assertEq(startSyBalanceOfYt - endSyBalanceOfYt, AMOUNT_SY);
        assertEq(endSyBalanceOfUser - startSyBalanceOfUser, AMOUNT_SY);
        assertEq(endSyBalanceOfYt, updatedSyReserve, "Failed to updated internal syReserve");
    }

    function testRedeemSyBurnsPtYtOfUser() external prank(USER) {
        // Arrange
        (uint256 amountPt,) = _stripSy(USER, AMOUNT_SY);
        _afterExpiry();

        uint256 startPtBalanceOfUser = pt.balanceOf(USER);
        uint256 startYtBalanceOfUser = yt.balanceOf(USER);
        uint256 startPtTotalSupply = pt.totalSupply();
        uint256 startYtTotalSupply = yt.totalSupply();

        // Act
        yt.redeemSy(USER, amountPt);

        uint256 endPtBalanceOfUser = pt.balanceOf(USER);
        uint256 endYtBalanceOfUser = yt.balanceOf(USER);
        uint256 endPtTotalSupply = pt.totalSupply();
        uint256 endYtTotalSupply = yt.totalSupply();

        assertEq(startPtBalanceOfUser - endPtBalanceOfUser, amountPt);
        assertEq(startYtBalanceOfUser - endYtBalanceOfUser, amountPt);
        assertEq(startPtTotalSupply - endPtTotalSupply, amountPt);
        assertEq(startYtTotalSupply - endYtTotalSupply, amountPt);
    }

    function testRedeemSyBeforeExpiryRedeemsAdjustedSy() external prank(USER) {
        (uint256 amountPt, uint256 _amountYt) = _stripSy(USER, AMOUNT_SY);
        uint256 amountYt = _amountYt / 2;

        uint256 startSyBalanceOfUser = sy.balanceOf(USER);

        yt.redeemSyBeforeExpiry(USER, amountPt, amountYt);

        uint256 endSyBalanceOfUser = sy.balanceOf(USER);
        uint256 expectedEndSyBalanceOfUser = amountYt.divDown(sy.exchangeRate());

        assertEq(endSyBalanceOfUser - startSyBalanceOfUser, expectedEndSyBalanceOfUser);
    }

    function testRedeemSyRevertsIfNotExpired() external prank(USER) {
        // Arrange
        (uint256 amountPt,) = _stripSy(USER, AMOUNT_SY);

        vm.expectRevert();
        yt.redeemSy(USER, amountPt);
    }

    function testRedeemSyBeforeExpiryRevertsIfExpired() external prank(USER) {
        // Arrange
        (uint256 amountPt, uint256 amountYt) = _stripSy(USER, AMOUNT_SY);

        _afterExpiry();
        vm.expectRevert();
        yt.redeemSyBeforeExpiry(USER, amountPt, amountYt);
    }

    function _stripSy(address user, uint256 amountSy) internal returns (uint256 amountPt, uint256 amountYt) {
        _mintSYForUser(sy, user, amountSy);
        sy.approve(address(yt), amountSy);
        (amountPt, amountYt) = yt.stripSy(user, amountSy);
    }

    function _afterExpiry() internal {
        vm.warp(EXPIRY);
    }

    function testCurrentExchangeRateIsValid() external {
        uint256 currentExchangeRate = yt.currentExchangeRate();
        uint256 syExchangeRate = sy.exchangeRate();

        assert(currentExchangeRate >= syExchangeRate);
    }

    /*///////////////////////////////////////////////////////////////
                           TESTS for External-View Functions
    //////////////////////////////////////////////////////////////*/

    function testYTMetadata() external view {
        string memory ytName = yt.name();
        string memory ytSymbol = yt.symbol();

        string memory expectedYtName = "YT Lido wstETH";
        string memory expectedYtSymbol = "YT-wstETH";

        assertEq(ytName, expectedYtName);
        assertEq(ytSymbol, expectedYtSymbol);
    }

    function testPTForYT() external view {
        address ptForyt = yt.PT();
        address expectedPtForYt = address(pt);

        assertEq(ptForyt, expectedPtForYt);
    }

    function testSYForYT() external view {
        address syForYt = yt.SY();
        address expectedSyForYt = address(sy);

        assertEq(syForYt, expectedSyForYt);
    }

    function testYTExpiry() external view {
        uint256 ytExpiry = yt.expiry();
        uint256 expectedYtExpiry = EXPIRY;

        assertEq(ytExpiry, expectedYtExpiry);
    }

    function testYTIsExpiredBeforeExpiry() external view {
        bool response = yt.isExpired();
        bool expectedResponse = false;

        assertEq(response, expectedResponse);
    }

    function testYTIsExpiredAfterExpiry() external {
        vm.warp(EXPIRY);

        bool response = yt.isExpired();
        bool expectedResponse = true;

        assertEq(response, expectedResponse);
    }
}
