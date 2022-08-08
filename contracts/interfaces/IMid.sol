// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IMid is IERC721Enumerable {
    struct Properties{
        uint256 birthblock;
        bytes3 rarity;
        uint256 seed;
    }
    function getNameOfTokenId(uint256 _tokenId) external view returns (string memory);
    function getProperty(uint256 tokenId) external view returns (Properties memory);
}