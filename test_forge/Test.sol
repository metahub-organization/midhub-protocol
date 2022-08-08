
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
contract Test {

    function withdraw (address from, address to, uint256 tokenId) public{
        IERC721(0xDA5AB630E2B1740396FfcD8FB83098914c17269b).transferFrom(from, to, tokenId);
    }

}