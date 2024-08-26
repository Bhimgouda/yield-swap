// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PrincipalToken is ERC20 {
    address private immutable i_sy;
    address private i_yt;
    uint256 private immutable i_expiry;
    address private immutable i_factory;

    modifier onlyFactory() {
        require(msg.sender == i_factory);
        _;
    }

    modifier onlyYt() {
        require(msg.sender == i_yt);
        _;
    }

    constructor(
        address sy,
        string memory name,
        string memory symbol,
        uint256 expiry
    ) ERC20(name, symbol) {
        i_sy = sy;
        i_expiry = expiry;
    }

    function initialize(address yt) external onlyFactory {
        require(i_yt == address(0), "Already Initialized");
        i_yt = yt;
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
}
