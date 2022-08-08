// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface IRoyaltyOracle{
    function token() external view returns (IERC20);

    function price() external view returns (uint256);
}