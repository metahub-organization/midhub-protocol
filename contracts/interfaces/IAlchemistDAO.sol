
// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.3;

interface IAlchemistDAO {
    function balanceOfTokenId(uint256 tokenId) external view returns(uint256);
    function withdrawnOf(uint256 tokenId) external view returns(uint256);
}