// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface ISketchComponent {
    function data(uint256) external pure returns (string memory);
    function data(string memory color) external pure returns (string memory);
    function data(uint256, string memory color) external pure returns (string memory);
    function data(uint256, string memory color, string memory colorPlus) external pure returns (string memory);
}