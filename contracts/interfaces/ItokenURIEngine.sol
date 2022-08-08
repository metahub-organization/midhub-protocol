
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ItokenURIEngine {
    function render(uint256) external view returns (string memory);
}