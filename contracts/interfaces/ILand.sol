// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface ILand is IERC721Enumerable {
    function updateMember(uint256 tokenIdOfLand, uint256 tokenIdOfMid) external;
    function getNameOfTokenId(uint256 _tokenId) external view returns (string memory);
    function countOfMembers(uint256 tokenId) external view returns (uint256);
}