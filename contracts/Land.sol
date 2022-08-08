// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./DNS/BaseRegistrarImplementation.sol";
import "./TokenURISetting.sol";
import "./Royalty.sol";
import "./utils/Byte.sol";
import "./utils/StringLib.sol";

contract Land is Royalty, AccessControl, BaseRegistrarImplementation, Pausable, TokenURISetting {
    bytes32 private constant ROOT_NODE = bytes32(0);
    bytes32 public constant LAND_ADMIN = keccak256("LAND_ADMIN");
    bytes32 public constant TOKENURI_ENGINE_ROLE = keccak256("TOKENURI_ENGINE_ROLE");
    bytes32 public constant ROYALTY_ORACLE_ROLE = keccak256("ROYALTY_ORACLE_ROLE");
    address private _midAddress;
    IERC20 _MIDCoin;
    mapping(uint256 => uint256[]) private  _membersOfLand;

    using StringLib for string;
    using SafeERC20 for IERC20;

    event CallUpdateMember(uint256 indexed tokenIdOfLand, uint256 indexed tokenIdOfMid );

    constructor(
        NNS nns_,
        address timelockController,
        address erc20TransferHelper_,
        ITreasury micTreasury_,
        ITreasury midLandTreasury_,
        ITreasury alchemistTreasury_,
        address micAddress_,
        address midAddress_) BaseRegistrarImplementation("Land", "LAND", nns_) Royalty(erc20TransferHelper_, micTreasury_, midLandTreasury_, alchemistTreasury_){
        _setRoleAdmin(LAND_ADMIN, LAND_ADMIN);
        require(timelockController != address(0), "Timelock controller address is invalid");
        _setRoleAdmin(TOKENURI_ENGINE_ROLE, LAND_ADMIN);
        _setRoleAdmin(ROYALTY_ORACLE_ROLE, LAND_ADMIN);
        _setupRole(LAND_ADMIN, timelockController);
        _setupRole(TOKENURI_ENGINE_ROLE, timelockController);
        _setupRole(ROYALTY_ORACLE_ROLE, timelockController);

        _midAddress = midAddress_;
        _MIDCoin = IERC20(micAddress_);
    }

    /**
     * @dev Returns current token price.
     */
    function priceOracle(uint256 count) internal pure returns(uint256) {
        if (count == 0) {
            return 0;
        }
        uint256 epoch = (count - 1) / 1000;
        return 500 ether + epoch * 10 ether;
    }

    /**
     * @dev Returns the mid token address.
     */
    function midAddress() external view returns (address) {
        return _midAddress;
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

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        require(_exists(tokenId), "id does not exist");
        string memory name = getNameOfTokenId(tokenId);
        ItokenURIEngine tokenURIEngine_ = tokenURIEngine();
        string memory render =  tokenURIEngine_.render(tokenId);
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "', name,'", "description": "Land is the NFTPass for MIDHub Protocol.", ', render, '}'))));
        string memory output = string(abi.encodePacked('data:application/json;base64,', json));
        return output;
    }

    function mint(string memory name_) external nonReentrant {
        uint256 _currentPrice = currentPrice();
        (bytes32 name, bytes32 rootName) = name_.nameSplit();
        require(rootName == 0x4fdac1bbc9dbc33823c8a52d84a71ee2173f60f5d76132e2f79e5aeae8219887, "Root name format error");
        bytes32 parentsNode = keccak256(abi.encodePacked(ROOT_NODE, rootName));
        bytes32 subNode = keccak256(abi.encodePacked(parentsNode, name));
        uint256 tokenId = uint256(subNode);
        require(!_exists(tokenId) && nns.ownerOf(subNode) == address(0x0), "Name has been registered");
        _nameOfTokenId[tokenId] =  Byte.stringToBytes32(name_);
        _tokenIdOfName[ Byte.stringToBytes32(name_)] = tokenId;
        _safeMint(msg.sender, tokenId);
        _register(parentsNode,  name, address(this));
        
        bytes32 subParentsNode = keccak256(abi.encodePacked(ROOT_NODE, name));
        require(nns.ownerOf(subParentsNode) == address(0x0), "Land has been registered");
        require(_midAddress != address(0x0), "MID is not initialized");
        _register(ROOT_NODE, name, _midAddress);

        uint256 balanceOf = _MIDCoin.balanceOf(_msgSender());
        if(_currentPrice > 0){
            require(balanceOf >= _currentPrice, "Not enough balance.");
            _MIDCoin.safeTransferFrom(msg.sender, address(this), _currentPrice);
            _MIDCoin.safeTransfer(address(0x000000000000000000000000000000000000dEaD), _currentPrice*2/10);
            _MIDCoin.safeTransfer(_midLandTreasury, _currentPrice*5/10);
            _MIDCoin.safeTransfer(_alchemistTreasury, _currentPrice*3/10);
        }
    }

    /**
     * @dev Returns the token uri of the given name.
     */
    function  tokenURIByName(string memory name_) external view returns (string memory) {
        uint256 tokenId = getTokenIdOfName(name_);
        return tokenURI(tokenId);
    }
    /**
     * @dev Returns the price.
     */
    function currentPrice() public view returns (uint256) {
        return priceOracle(totalSupply());
    }

    function updateMember(uint256 tokenIdOfLand, uint256 tokenIdOfMid) external nonReentrant {
        require(_exists(tokenIdOfLand), "land does not exist");
        require(msg.sender == _midAddress, "only mid owner can update member");
        _membersOfLand[tokenIdOfLand].push(tokenIdOfMid);
        emit CallUpdateMember(tokenIdOfLand, tokenIdOfMid);
    }

    /**
     * @dev Returns the member count of the given token id.
     */
    function countOfMembers(uint256 tokenId) external view returns (uint256) {
        return _membersOfLand[tokenId].length;
    }

    /**
     * @dev Returns the members of the given token id.
     */
    function members(uint256 tokenId) external view returns (uint256[] memory) {
        return _membersOfLand[tokenId];
    }

    /// @dev set tokenURIEngine's address.
    function setTokenURIEngine(address tokenURIEngine__) external nonReentrant {
        require(hasRole(TOKENURI_ENGINE_ROLE, msg.sender), "No permission");
        _setTokenURIEngine(tokenURIEngine__);
    }

    /// @dev Set royaltyOracle's address.
    function setRoyaltyOracle(address royaltyOracle_) external nonReentrant {
        require(hasRole(ROYALTY_ORACLE_ROLE, msg.sender), "No permission");
        _setRoyaltyOracle(royaltyOracle_);
    }

    function supportsInterface(bytes4 interfaceId) public view override(BaseRegistrarImplementation, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        require(!paused(), "ERC721Pausable: token transfer while paused");
        super._beforeTokenTransfer(from, to, tokenId);
        compute(from, to, tokenId);
    }
}