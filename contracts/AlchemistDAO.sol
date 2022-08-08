
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/IAlchemistDAO.sol";
contract AlchemistDAO is ReentrancyGuard, IAlchemistDAO {
    using SafeERC20 for IERC20;
    uint256 private totalWithdrawal;
    mapping(uint256 => uint256) private withdrawn;
    address private immutable _mic;
    address private immutable _alchemist;
    address private immutable _alchemistTreasury;

    event CallWithdraw(address alchemist, uint256 indexed tokenId, uint256 amount);
    constructor(address mic_, address alchemist_, address alchemistTreasury_){
        _mic = mic_;
        _alchemist = alchemist_;
        _alchemistTreasury = alchemistTreasury_;
    }

    /**
     * @dev Returns the MIC address
     */
    function mic() external view returns (address) {
        return _mic;
    }

    /**
     * @dev Returns the Alchemist address
     */
    function alchemist() external view returns (address) {
        return _alchemist;
    }

    /**
     * @dev Returns the AlchemistTreasury address
     */
    function alchemistTreasury() external view returns (address) {
        return _alchemistTreasury;
    }

    /**
     * @dev Returns the total amount of tokens withdrawn
     */
    function totalWithdrawalOf() external view returns (uint256) {
        return totalWithdrawal;
    }

    /// @return Number of tokens withdrawn this time
    function withdraw (uint256 tokenId) external nonReentrant returns(uint256){
        assert(msg.sender == IERC721(_alchemist).ownerOf(tokenId));
        IERC20 __mic = IERC20(_mic);
        uint256 totalAmount = __mic.balanceOf(_alchemistTreasury) + totalWithdrawal;
        require((totalAmount / 3000) > withdrawn[tokenId], "You have already withdrawn this token");
        uint256 amount = (totalAmount / 3000) - withdrawn[tokenId];
        withdrawn[tokenId] += amount;
        totalWithdrawal += amount;
        emit CallWithdraw(_alchemist, tokenId, amount);
        ITreasury(_alchemistTreasury).handleOutgoingTransfer(msg.sender, amount, _mic);
        require(__mic.balanceOf(_alchemistTreasury) + totalWithdrawal == totalAmount, 'Withdrawal failed');
        return amount;
    }

    /**
     * @return Balance of the tokenId
     */
    function balanceOfTokenId(uint256 tokenId) external view returns(uint256){
        IERC20 __mic = IERC20(_mic);
        require(tokenId >= 1000 && tokenId < 4000, 'TokenId out of range');
        uint256 totalAmount = __mic.balanceOf(_alchemistTreasury) + totalWithdrawal;
        if ((totalAmount / 3000) > withdrawn[tokenId]) {
            uint256 amount = (totalAmount / 3000) - withdrawn[tokenId];
            return amount;
        }
        return uint256(0);
    }

    /**
     * @return Total amount withdrawn by tokenId
     */
    function withdrawnOf(uint256 tokenId) external view returns(uint256){
        require(tokenId >= 1000 && tokenId < 4000, 'TokenId out of range');
        return withdrawn[tokenId];
    }

}