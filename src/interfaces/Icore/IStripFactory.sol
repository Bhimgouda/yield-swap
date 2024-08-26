// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.24;

interface IStripFactory {
    function _generatePtYtMetadata(
        address sy
    )
        external
        view
        returns (string memory, string memory, string memory, string memory);
}
