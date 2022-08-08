
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Mic is ERC20Permit, Ownable, Pausable, ReentrancyGuard {
    address private immutable _midAddress;
    constructor(address midAddress) ERC20("MIDCoin", "MIC") ERC20Permit("MIDCoin") {
        _midAddress = midAddress;
    }

    function mint(address account, uint256 amount) external nonReentrant {
        require(msg.sender == _midAddress, "Only owner can mint");
        _mint(account, amount);
    }
    /**
     * @dev Pause the contract.
     */
    function pause() external whenNotPaused onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the contract.
     */
    function unpause() external whenPaused onlyOwner {
        _unpause();
    }

}
