// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBaseTransferHelper {
    function isModuleApproved(address _user) external view returns (bool);
}