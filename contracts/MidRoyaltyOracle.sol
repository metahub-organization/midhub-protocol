// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IRoyaltyOracle.sol";

contract MidRoyaltyOracle is IRoyaltyOracle {
    uint256 public immutable ROYALTY;
    address public immutable TOKEN;
    
    constructor(address token_, uint256 ROYALTY_) {
        TOKEN = token_;
        ROYALTY = ROYALTY_;
    }

    function token() external view override returns (IERC20) {
        return IERC20(TOKEN);
    }

    function price() external view override returns (uint256) {
        return ROYALTY;
    }
}
