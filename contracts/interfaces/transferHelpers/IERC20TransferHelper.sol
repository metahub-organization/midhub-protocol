// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IBaseTransferHelper.sol";

interface IERC20TransferHelper is IBaseTransferHelper {
    function safeTransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _value
    ) external;
}