
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Strings.sol";
library Uints {
    function uintToHex(uint256 decimalValue) pure internal returns (string memory) {
        uint remainder;
        bytes memory hexResult = "#";
        string[16] memory hexDictionary = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"];

        for (uint i = 0; decimalValue != 0 && i < 6; i++) {
            remainder = decimalValue % 16;
            string memory hexValue = hexDictionary[remainder];
            hexResult = abi.encodePacked(hexResult, hexValue);
            decimalValue = decimalValue / 16;
        }
        
        // Account for missing leading zeros
        uint len = hexResult.length;

        if (len == 6) {
            hexResult = abi.encodePacked(hexResult, "0");
        } else if (len == 5) {
            hexResult = abi.encodePacked(hexResult, "00");
        } else if (len == 4) {
            hexResult = abi.encodePacked(hexResult, "000");
        } else if (len == 3) {
            hexResult = abi.encodePacked(hexResult, "0000");
        } else if (len == 2) {
            hexResult = abi.encodePacked(hexResult, "00000");
        } else if (len == 1) {
            hexResult = abi.encodePacked(hexResult, "000000");
        }

        return string(hexResult);
    }

    function uintToEther(uint256 input) internal pure returns (string memory) {
        string memory output;
        if (input == 0) {
            return '0 MIC';
        } else if (input < 1* 10 ** 15) {
            return '< 0.001 MIC';
        } else {
            output = string(abi.encodePacked(Strings.toString(input / 1 ether), '.'));
            uint256 mod = input % 1 ether;
            output = string(abi.encodePacked(output, Strings.toString(mod / 10 ** 17)));
            mod = input % 10 ** 17;
            output = string(abi.encodePacked(output, Strings.toString(mod / 10 ** 16)));
            mod = input % 10 ** 16;
            output = string(abi.encodePacked(output, Strings.toString(mod / 10 ** 15), ' MIC'));
            return string(output);
        }
    }
}