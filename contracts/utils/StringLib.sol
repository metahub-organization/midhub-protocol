// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

library StringLib {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint len_) internal pure {
        // Copy word-length chunks while possible
        for(; len_ >= 32; len_ -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - len_) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice's text.
     */
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

    /*
     * @dev Returns the keccak-256 hash of the slice.
     * @param self The slice to hash.
     * @return The hash of the slice.
     */
    function keccak(slice memory self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr = selfptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                uint end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr >= end)
                        return selfptr + selflen;
                    ptr++;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }


    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and `token` to everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function split(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

    /*
     * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return The number of occurrences of `needle` found in `self`.
     */
    function count(slice memory self, slice memory needle) internal pure returns (uint cnt) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }

    function lenOfChars(string memory src) internal pure returns (uint){
        uint i = 0;
        uint length = 0;
        bytes memory string_rep = bytes(src);
        //UTF-8 skip word
        while (i < string_rep.length)
        {
            i += utf8CharBytesLength(string_rep, i);
            length++;
        }
        return length;
    }

    function toLowercase(string memory src) internal pure returns (string memory){
        bytes memory srcb = bytes(src);
        for (uint i = 0; i < srcb.length; i++) {
            bytes1 b = srcb[i];
            if (b >= 'A' && b <= 'Z') {
                b |= 0x20;
                srcb[i] = b;
            }
        }
        return src;
    }

    //------------HELPER FUNCTIONS----------------

    function utf8CharBytesLength(bytes memory stringRep, uint ptr) internal pure returns (uint){

        if ((stringRep[ptr] >> 7) == bytes1(0))
            return 1;
        if ((stringRep[ptr] >> 5) == bytes1(0x06))
            return 2;
        if ((stringRep[ptr] >> 4) == bytes1(0x0e))
            return 3;
        if ((stringRep[ptr] >> 3) == bytes1(0x1e))
            return 4;
        return 1;
    }

    function nameSplit(string memory fullName) internal pure returns (bytes32, bytes32) {
        StringLib.slice  memory s = toSlice(fullName);
        StringLib.slice  memory delim = toSlice(".");
        require(count(s, delim) == 1, "name format error");
        StringLib.slice memory name;
        StringLib.slice memory rootName;
        split(s, delim, name);
        string memory _name = toString(name);
        require(lenOfChars(_name) > 0 && lenOfChars(_name) <= 16, "Length less than or equal to 16");
        checkName(_name);
        split(s, delim, rootName);
        return (keccak(name), keccak(rootName));
    }

    function checkName(string memory name) internal pure {
        bytes memory srcb = bytes(name);
        for (uint i = 0; i < srcb.length; i++) {
            require((srcb[i] >= 'a' && srcb[i] <= 'z') || (srcb[i] >= '0' && srcb[i] <= '9'), 'a-z,0-9');
        }
    }
}