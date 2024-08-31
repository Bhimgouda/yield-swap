// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {PrincipalToken} from "./PrincipalToken.sol";
import {YieldToken} from "./YieldToken.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {StringLib} from "../libraries/StringLib.sol";
import {console} from "forge-std/console.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract PtYtFactory is Ownable(msg.sender) {
    using StringLib for string;
    using StringLib for StringLib.slice;

    string constant PT_NAME_PREFIX = "PT ";
    string constant PT_SYMBOL_PREFIX = "PT-";
    string constant YT_NAME_PREFIX = "YT ";
    string constant YT_SYMBOL_PREFIX = "YT-";
    string constant SY_NAME_BEYOND = "SY ";
    string constant SY_SYMBOL_BEYOND = "SY-";
    uint256 public constant MAX_INTEREST_FEE_RATE = 15e16; // 15%
    uint256 public constant MIN_INTEREST_FEE_RATE = 25e15; // 2.5%

    // Fee to be charged on interest earned
    uint256 private s_interestFeeRate;

    // Treasury address for receiving fees
    address private s_treasury;

    modifier interestFeeRateInRange(uint256 _interestFeeRate) {
        require(
            MIN_INTEREST_FEE_RATE < _interestFeeRate && _interestFeeRate < MAX_INTEREST_FEE_RATE,
            "Interest Fee Rate Out of Range"
        );
        _;
    }

    modifier validTreasury(address treasury) {
        require(treasury != address(0), "Treasury address cannot be Zero");
        _;
    }

    constructor(uint256 interestFeeRate, address treasury)
        interestFeeRateInRange(interestFeeRate)
        validTreasury(treasury)
    {
        s_interestFeeRate = interestFeeRate;
        s_treasury = treasury;
    }

    function createPtYt(address sy, uint256 expiry) external returns (address pt, address yt) {
        (string memory ptName, string memory ptSymbol, string memory ytName, string memory ytSymbol) =
            _generatePtYtMetadata(sy);

        PrincipalToken PT = new PrincipalToken(sy, ptName, ptSymbol, expiry);

        YieldToken YT = new YieldToken(sy, address(PT), ytName, ytSymbol, expiry);

        PT.initialize(address(YT));

        pt = address(PT);
        yt = address(YT);
    }

    function setInterestFeeRate(uint256 newInterestFeeRate)
        external
        onlyOwner
        interestFeeRateInRange(newInterestFeeRate)
    {
        s_interestFeeRate = newInterestFeeRate;
    }

    function setTreasury(address newTreasury) external onlyOwner validTreasury(newTreasury) {
        s_treasury = newTreasury;
    }

    /*///////////////////////////////////////////////////////////////
                            Internal Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev generates the pt and yt name based on the sy's metadata
     */
    function _generatePtYtMetadata(address sy)
        internal
        view
        returns (string memory ptName, string memory ptSymbol, string memory ytName, string memory ytSymbol)
    {
        (string memory _syName, string memory _sySymbol) = _getSyMetadata(sy);

        StringLib.slice memory syName = _syName.toSlice();
        StringLib.slice memory sySymbol = _sySymbol.toSlice();
        StringLib.slice memory syNameBeyond = SY_NAME_BEYOND.toSlice();
        StringLib.slice memory sySymbolBeyond = SY_SYMBOL_BEYOND.toSlice();

        ptName = StringLib.concat(PT_NAME_PREFIX.toSlice(), syName.beyond(syNameBeyond));

        ptSymbol = StringLib.concat(PT_SYMBOL_PREFIX.toSlice(), sySymbol.beyond(sySymbolBeyond));

        ytName = StringLib.concat(YT_NAME_PREFIX.toSlice(), syName.beyond(syNameBeyond));

        ytSymbol = StringLib.concat(YT_SYMBOL_PREFIX.toSlice(), sySymbol.beyond(sySymbolBeyond));
    }

    function _getSyMetadata(address sy) internal view returns (string memory name, string memory symbol) {
        name = IERC20Metadata(sy).name();
        symbol = IERC20Metadata(sy).symbol();
    }

    /*///////////////////////////////////////////////////////////////
                            External View
    //////////////////////////////////////////////////////////////*/

    function getInterestFeeRate() external view returns (uint256) {
        return s_interestFeeRate;
    }

    function getTreasury() external view returns (address) {
        return s_treasury;
    }
}
