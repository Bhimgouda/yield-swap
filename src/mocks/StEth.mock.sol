// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract StEth is ERC20("Staked Liquid Ether", "StEth") {
    function mint(address user, uint256 amount) external {
        _mint(user, amount);
    }
}
