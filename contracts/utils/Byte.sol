
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Byte {    
    function bytes3ToBytes(bytes3 _bytes3) internal pure returns (bytes memory) {
        uint8 i = 0;
        while(i < 3 && _bytes3[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 3 && _bytes3[i] != 0; i++) {
            bytesArray[i] = _bytes3[i];
        }
        return bytesArray;
    }

    function bytes32ToBytes(bytes32 _bytes32) internal pure returns (bytes memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return bytesArray;
    }

    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        return string(bytes32ToBytes(_bytes32));
    }

    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
}