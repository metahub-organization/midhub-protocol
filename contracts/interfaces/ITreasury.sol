
// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.3;

interface ITreasury {
    function withdrawn(address currency) external view returns (uint256);
    function handleOutgoingTransfer(
        address dest,
        uint256 amount,
        address currency
    ) external;
}