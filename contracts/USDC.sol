// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract USDC is ERC20Permit, Ownable, Pausable, ReentrancyGuard {
    constructor() ERC20("USD Coin", "USDC") ERC20Permit("USDC") {
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function mint() external {
        _mint(msg.sender, 10000 * (10**decimals()));
    }

    /**
     * @dev Pause the contract.
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpause the contract.
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

}
