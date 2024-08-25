// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title Mock DAI
 * @author Bhimgouda Patil
 * @notice This is just a mock of DAI stablecoin
 */
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Dai is ERC20("DAI Token", "DAI") {
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
