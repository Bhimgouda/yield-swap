// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PrincipalToken is ERC20 {
    address public immutable SY;
    address public YT;
    uint256 private immutable i_expiry;
    address private immutable i_factory;

    modifier onlyFactory() {
        require(msg.sender == i_factory);
        _;
    }

    modifier onlyYt() {
        require(msg.sender == YT);
        _;
    }

    constructor(address _SY, string memory _name, string memory _symbol, uint256 _expiry) ERC20(_name, _symbol) {
        SY = _SY;
        i_expiry = _expiry;
        i_factory = msg.sender;
    }

    function initialize(address yt) external onlyFactory {
        require(YT == address(0), "Already Initialized");
        YT = yt;
    }

    function mintByYt(address to, uint256 amount) external onlyYt {
        _mint(to, amount);
    }

    function burnByYt(address from, uint256 amount) external onlyYt {
        _burn(from, amount);
    }

    /*///////////////////////////////////////////////////////////////
                            MISC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function isExpired() external view returns (bool) {
        return block.timestamp < i_expiry ? false : true;
    }

    function expiry() external view returns (uint256) {
        return i_expiry;
    }

    function factory() external view returns (address) {
        return i_factory;
    }
}
