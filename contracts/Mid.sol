// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "./DNS/BaseRegistrarImplementation.sol";
import "./interfaces/ILand.sol";
import "./TokenURISetting.sol";
import "./Royalty.sol";
import "./interfaces/IMIC.sol";
import "./utils/Rand.sol";
import "./utils/StringLib.sol";

contract Mid is VRFConsumerBaseV2, Royalty, AccessControl, BaseRegistrarImplementation, Pausable, TokenURISetting, Initializable {
    struct Properties{
        uint256 birthblock;
        bytes3 rarity;
        uint256 seed;
    }
    mapping(uint256 => Properties) private _properties;
    bytes32 private constant ROOT_NODE = bytes32(0);
    bytes32 public constant META_ID_ADMIN = keccak256("META_ID_ADMIN");
    bytes32 public constant TOKENURI_ENGINE_ROLE = keccak256("TOKENURI_ENGINE_ROLE");
    bytes32 public constant VRF_ROLE = keccak256("VRF_ROLE");
    bytes32 public constant ROYALTY_ORACLE_ROLE = keccak256("ROYALTY_ORACLE_ROLE");
    bytes32 public constant META_ID_CONTRACT_ROLE = keccak256("META_ID_CONTRACT_ROLE");
    uint256 constant public _midTotalSupply = 100000;
    address private _landAddress;
    IMIC private _micToken;
    address payable _fundTreasury;
    IERC20 private _usdc;

    VRFCoordinatorV2Interface internal immutable vrfCoordinator;
    bytes32 private keyHash;
    uint64 private subscriptionId;
    uint32 private callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;
    uint16 private requestConfirmations;
    mapping(uint256 => uint256) private requestRandomToTokenId;

    using StringLib for string;
    using SafeERC20 for IERC20;
    constructor(
        NNS nns_,
        address timelockController,
        address erc20TransferHelper_,
        ITreasury micTreasury_,
        ITreasury midLandTreasury_,
        ITreasury alchemistTreasury_,
        ITreasury fundTreasury_,
        address _vrfCoordinator) VRFConsumerBaseV2(_vrfCoordinator) BaseRegistrarImplementation("MetaID", "MID", nns_) Royalty(erc20TransferHelper_, micTreasury_, midLandTreasury_, alchemistTreasury_) {
        _setRoleAdmin(META_ID_ADMIN, META_ID_ADMIN);
        require(timelockController != address(0), "Timelock controller address is invalid");
        _setRoleAdmin(TOKENURI_ENGINE_ROLE, META_ID_ADMIN);
        _setRoleAdmin(VRF_ROLE, META_ID_ADMIN);
        _setRoleAdmin(META_ID_CONTRACT_ROLE, META_ID_ADMIN);
        _setRoleAdmin(ROYALTY_ORACLE_ROLE, META_ID_ADMIN);
        _setupRole(META_ID_ADMIN, timelockController);
        _setupRole(TOKENURI_ENGINE_ROLE, timelockController);
        _setupRole(VRF_ROLE, timelockController);
        _setupRole(ROYALTY_ORACLE_ROLE, timelockController);
        _fundTreasury = payable(address(fundTreasury_));

        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
    }

    /**
     * @dev Initializes the contract with the given parameters.
     */
    function init(address micAddress_, address landAddress_, IERC20 usdc_) external initializer {
        _landAddress = landAddress_;
        _micToken =  IMIC(micAddress_);
        _usdc = usdc_;
    }

    function setVRF(
        bytes32 _keyHash,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations) external nonReentrant {
        require(hasRole(VRF_ROLE, msg.sender), "No permission");

        keyHash = _keyHash;
        subscriptionId = _subscriptionId;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
    }

    /**
     * @dev Returns current token price.
     */
    function priceOracle(uint256 count) public pure returns(uint256) {
        uint256 epoch = count / 1000;
        return 2 * 10 ** 8 * 105 ** epoch / 100 ** epoch;
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
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "', name, '", "description": "MID is an Onchain SVG NFT DID for Web3.",', render, '}'))));
        string memory output = string(abi.encodePacked('data:application/json;base64,', json));
        return output;
    }

    /**
     * @dev Current mint price of the token.
     */
    function currentPrice() public view returns (uint256) {
        return priceOracle(totalSupply());
    }

    /**
     * @dev Mint *.mid in mid.land .
     */
    function mintMid(string memory name) nonReentrant external {
        require(mintedOfMid() < _midTotalSupply, "Mid has been completed");
        (, bytes32 rootName) = name.nameSplit();
        require(rootName == keccak256(bytes("mid")), "name must be mid land");
        require(_usdc.allowance(_msgSender(), address(this)) >= currentPrice(), "Not enough approve tokens");
        require(_micTreasury != address(0) && _midLandTreasury != address(0) && _alchemistTreasury != address(0) && _fundTreasury != address(0), "Address cannot be 0");
        _usdc.safeTransferFrom(msg.sender, _fundTreasury, currentPrice());
        _micToken.mint(msg.sender, 300 ether);
        _micToken.mint(_micTreasury, 200 ether);
        _micToken.mint(_midLandTreasury, 200 ether);
        _micToken.mint(_alchemistTreasury, 300 ether);
        this.mintRoute(name, msg.sender);
    }
    function mintRoute(string memory name, address owner_) external {
        require(hasRole(META_ID_CONTRACT_ROLE, msg.sender) || msg.sender == address(this), "Only land or self can mint");
        (bytes32 namePrefix, bytes32 rootName) = name.nameSplit();
        uint256 landTokenId = _landTokenId(rootName);
        require(ILand(_landAddress).ownerOf(landTokenId) != address(0x0));
        bytes32 parentsNode = keccak256(abi.encodePacked(ROOT_NODE, rootName));
        bytes32 subNode = keccak256(abi.encodePacked(parentsNode, namePrefix));
        uint256 tokenId = uint256(subNode);
        require(!_exists(tokenId) && nns.ownerOf(subNode) == address(0x0), "Name has been registered");

        _nameOfTokenId[tokenId] = Byte.stringToBytes32(name);
        _tokenIdOfName[Byte.stringToBytes32(name)] = tokenId;
        
        _safeMint(owner_, tokenId);
        _register(parentsNode,  namePrefix, address(this));

        ILand(_landAddress).updateMember(landTokenId, tokenId);

        uint256 requestId = vrfCoordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            NUM_WORDS
        );

        requestRandomToTokenId[requestId] = tokenId;
        _properties[tokenId].birthblock = block.number;
    }

    function _landTokenId(bytes32 label) internal pure returns (uint256) {
        bytes32 parentsNode = keccak256(abi.encodePacked(ROOT_NODE, keccak256(bytes("land"))));
        bytes32 subNode = keccak256(abi.encodePacked(parentsNode, label));
        uint256 _tokenId = uint256(subNode);
        return _tokenId;
    }

    /**
     * @dev Return count of *.mid have been minted.
     */
    function mintedOfMid() public view returns (uint256) {
        return ILand(_landAddress).countOfMembers(94328775775500535888815848536672232909525637833506754693101418770997277966841);
    }
    /**
     * @dev Returns the propery of the token.
     */
    function getProperty(uint256 tokenId) external view returns (Properties memory) {
        require(_exists(tokenId), "Name is not registered");
        return _properties[tokenId];
    }
    /**
     * @dev Returns the token uri of the given name.
     */
    function  tokenURIByName(string memory name_) external view returns (string memory) {
        uint256 tokenId = getTokenIdOfName(name_);
        return tokenURI(tokenId);
    }



    function rarity(uint256 seed) internal pure returns (bytes3 ratiryVal) {
        uint256 rarityRand = seed % 100;
        if (rarityRand <= 59) {
            return 'N';
        } else if (rarityRand > 59 && rarityRand <= 84) {
            return 'R';
        }else if (rarityRand > 84 && rarityRand <= 94) {
            return 'SR';
        }else if (rarityRand > 94 && rarityRand <= 98) {
            return 'SSR';
        } else if (rarityRand == 99) {
            return 'UR';
        }
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

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomNumbers)
        internal
        override
    {
        _properties[requestRandomToTokenId[requestId]].seed = randomNumbers[0];
        _properties[requestRandomToTokenId[requestId]].rarity = rarity(randomNumbers[0]);
    }

    /// @dev Royalty payments required prior to transfer
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
