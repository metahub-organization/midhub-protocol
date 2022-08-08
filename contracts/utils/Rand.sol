
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Strings.sol";

library Rand {
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getRand(string memory input, uint256 tokenId) internal pure returns (uint256) {
        return random(string(abi.encodePacked(input, Strings.toString(tokenId))));
    }
}