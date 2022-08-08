// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {OutgoingTransferSupport} from "./OutgoingTransferSupport/OutgoingTransferSupport.sol";
import {IWETH} from "./interfaces/common/IWETH.sol";
import "./interfaces/ITreasury.sol";

abstract contract Treasury is AccessControl, ReentrancyGuard, OutgoingTransferSupport, ITreasury {
    uint256 private constant USE_ALL_GAS_FLAG = 0;
    bytes32 public constant TREASURY_ADMIN = keccak256("TREASURY_ADMIN");
    bytes32 public constant SETTLEMENT_ROLE = keccak256("SETTLEMENT_ROLE");
    mapping(address => uint256) private _Withdrawn;

    /// @dev Emitted when a call to handleOutgoingTransfer is made.
    event Withdrawal(
        address indexed dest,
        uint256 amount,
        address currency
    );
    constructor(address wethAddress_, address timelockController) OutgoingTransferSupport(wethAddress_) {
        _setRoleAdmin(TREASURY_ADMIN, TREASURY_ADMIN);
        require(timelockController != address(0), "Timelock controller address is invalid");
        _setRoleAdmin(SETTLEMENT_ROLE, TREASURY_ADMIN);
        _setupRole(TREASURY_ADMIN, timelockController);
    }

    /**
     * @dev Contract might receive/hold ETH as part of the maintenance process.
     */
    receive() external payable {}

    /// @dev Modifier to make sure that the function is called by the settlement role.
    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(SETTLEMENT_ROLE, msg.sender), "Only settlement role can call this function");
    }

    /// @dev Query the amount of currency or ETH that has been withdrawn from the contract.
    /// @param currency The currency to be withdrawn.
    /// @return The amount of currency to be withdrawn.
    function withdrawn(address currency) external view override returns (uint256) {
        return _Withdrawn[currency];
    }

    /**
     * @dev Only settlement contracts are allowed to be withdrawn from here.
     * @param dest The address of the settlement contract.
     * @param amount The amount to withdraw.
     * @param currency The currency to withdraw.
     */
    function handleOutgoingTransfer(
        address dest,
        uint256 amount,
        address currency
    ) external restricted nonReentrant override {
        _handleOutgoingTransfer(dest, amount, currency, USE_ALL_GAS_FLAG);
        emit Withdrawal(dest, amount, currency);
        _Withdrawn[currency] += amount;
    }
}