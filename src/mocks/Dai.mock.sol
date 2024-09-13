// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DAI is ERC20("DAI Token", "DAI") {
    function mint(address user, uint256 amount) external {
        _mint(user, amount);
    }
}
