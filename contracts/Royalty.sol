// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/transferHelpers/IERC20TransferHelper.sol";
import "./IncomingTransferSupport/IncomingTransferSupport.sol";
import "./interfaces/IRoyaltyOracle.sol";
import "./interfaces/ITreasury.sol";
abstract contract Royalty is ReentrancyGuard, Context, IncomingTransferSupport{
    address payable immutable _micTreasury;
    address payable immutable _midLandTreasury;
    address payable immutable _alchemistTreasury;
    IRoyaltyOracle private _royaltyOracle;
    address private _erc20TransferHelper;

    mapping(uint256 => address) private preOwner;
    mapping(uint256 => address) private _paymentOfRoyalties;

    using Address for address;
    using SafeERC20 for IERC20;

    event CallPaymentOfRoyalties(uint256 indexed tokenId, address payer );
    event CallSetRoyaltyOracle(address royaltyOracle);
    constructor(address erc20TransferHelper_, ITreasury micTreasury_, ITreasury midLandTreasury_, ITreasury alchemistTreasury_) IncomingTransferSupport(erc20TransferHelper_) {
        _erc20TransferHelper = erc20TransferHelper_;
        _micTreasury = payable(address(micTreasury_));
        _midLandTreasury = payable(address(midLandTreasury_));
        _alchemistTreasury = payable(address(alchemistTreasury_));
    }

    /**
     * @dev Returns the mic treasury address.
     */
    function micTreasury() public view returns (address) {
        return _micTreasury;
    }

    /**
     * @dev Returns the midland treasury address.
     */
    function midLandTreasury() external view returns (address) {
        return _midLandTreasury;
    }

    /**
     * @dev Returns the alchemist treasury address.
     */
    function alchemistTreasury() external view returns (address) {
        return _alchemistTreasury;
    }

    /**
     * @dev Returns the royalty oracle address.
     */
    function royalteOracleAddress() external view returns (address) {
        return address(_royaltyOracle);
    }


    /**
     * @dev Returns the previous owner of the given token.
     */
    function previousOwnerOf(uint256 tokenId) external view returns (address) {
        return preOwner[tokenId];
    }

    /**
     * @dev Pay royalties for specified id.
     */
    function paymentOfRoyalties(uint256 tokenId) external nonReentrant {
        IERC20 token = _royaltyOracle.token();
        uint256 allowanceOf = token.allowance(_msgSender(), address(this));
        require(allowanceOf >= _royaltyOracle.price(), "Payments on behalf of Error");
        _paymentOfRoyalties[tokenId] = _msgSender();
        emit CallPaymentOfRoyalties(tokenId, _msgSender());
    }

    /// @dev Set royalty oracle address.
    function _setRoyaltyOracle(address royaltyOracle_) internal {
        _royaltyOracle = IRoyaltyOracle(royaltyOracle_);
        emit CallSetRoyaltyOracle(royaltyOracle_);
    }

    /// @dev Royalty payments required prior to transfer
    function compute(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        if (address(_royaltyOracle) != address(0)) {

            if(from != address(0) && preOwner[tokenId] != address(0)){
                IERC20 token = _royaltyOracle.token();
                uint256 ROYALTY = _royaltyOracle.price();
                uint256 allowanceOfErc20TransferHelper = token.allowance(preOwner[tokenId], _erc20TransferHelper);
                bool isAllowanceOfErc20TransferHelper =  _erc20TransferHelper != address(0) && IERC20TransferHelper(_erc20TransferHelper).isModuleApproved(preOwner[tokenId]) && allowanceOfErc20TransferHelper >= ROYALTY;
                uint256 allowanceOfroyaltyByPreOwner = token.allowance(preOwner[tokenId], address(this));
                address payerOf = _paymentOfRoyalties[tokenId];
                uint256 allowanceOfroyaltyByOther = token.allowance(payerOf, address(this));
                require(isAllowanceOfErc20TransferHelper ||  allowanceOfroyaltyByPreOwner >= ROYALTY || allowanceOfroyaltyByOther >= ROYALTY, "Approve for royalty not enough");
            
                if(to != address(0) && to != address(0x000000000000000000000000000000000000dEaD) && to != preOwner[tokenId] && ROYALTY != 0 && !to.isContract()) {
                    if (isAllowanceOfErc20TransferHelper) {
                        _handleIncomingTransfer(preOwner[tokenId], ROYALTY, address(token));
                    } else {
                        address payer;
                        if (allowanceOfroyaltyByPreOwner >= ROYALTY) {
                            payer = preOwner[tokenId];
                        } else if(allowanceOfroyaltyByOther >= ROYALTY){
                            payer = payerOf;
                        }
                        require(payer != address(0), "Insufficient balance");
                        token.safeTransferFrom(payer, address(this), ROYALTY);
                    }
                    token.safeTransfer(_alchemistTreasury, ROYALTY*3/10);
                    token.safeTransfer(_micTreasury, ROYALTY*2/10);
                    token.safeTransfer(_midLandTreasury, ROYALTY*5/10);
                }
            }

            if(!to.isContract()){
                preOwner[tokenId] = to;
            }
        } else {
            if(preOwner[tokenId] != address(0) && to != preOwner[tokenId] && !to.isContract()){
                preOwner[tokenId] = address(0);
            }
        }

    }
}
