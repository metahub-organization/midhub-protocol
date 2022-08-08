// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./NNS.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../utils/Byte.sol";
abstract contract BaseRegistrarImplementation is Ownable, ERC721Enumerable  {
    event NameRegistered(bytes32 indexed label, address indexed owner);

    NNS immutable nns;
    mapping(uint256 => bytes32)  _nameOfTokenId;
    mapping(bytes32 => uint256)  _tokenIdOfName;
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view override returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    constructor(string memory name_, string memory symbol_, NNS _nns) ERC721(name_, symbol_) {
        nns = _nns;
    }

    modifier live(bytes32 baseNode) {
        require(nns.ownerOf(baseNode) == address(this) || nns.isApprovedForAll(nns.ownerOf(baseNode), address(this)), "BaseRegistrarImplementation: Caller is not approved or not the owner");
        _;
    }

    modifier ownerOfname(bytes32 node) {
        require(_isApprovedOrOwner(msg.sender, uint256(node)), "BaseRegistrarImplementation: Caller is not the owner");
        _;
    }

    /**
     * @dev Returns the name of the given token id.
     */
    function getNameOfTokenId(uint256 _tokenId) public view returns (string memory) {
        return string(Byte.bytes32ToString(_nameOfTokenId[_tokenId]));
    }

    /**
     * @dev Returns the token id of the given name.
     */
    function getTokenIdOfName(string memory name_) public view returns (uint256) {
        return _tokenIdOfName[Byte.stringToBytes32(name_)];
    }

    // Set the resolver for the TLD this registrar manages.
    function setResolver(bytes32 node, address resolver) public ownerOfname(node) {
        nns.setResolver(node, resolver);
    }
    function setResolverByName(string memory name, address resolver) external {
        uint256 tokenId = getTokenIdOfName(name);
        setResolver(bytes32(tokenId), resolver);
    }

    function _register(bytes32 baseNode, bytes32 label, address owner) internal live(baseNode) returns(bytes32) {
        emit NameRegistered(label, owner);
        bytes32 subnode = nns.setSubnodeOwner(baseNode, label, owner);
        return subnode;
    }
    
    function supportsInterface(bytes4 interfaceId) public virtual override(ERC721Enumerable) view returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
