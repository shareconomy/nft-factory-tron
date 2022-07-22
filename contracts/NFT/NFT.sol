// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title NFT contract which implements strandart TRC721 but with some advanced features
/// @author AkylbekAD
/// @notice TRC721 contract

import "./utils/Strings.sol";
import "./utils/AccessControl.sol";
import "./utils/Counters.sol";
import "./TRC721.sol";

contract NFT is TRC721, AccessControl {
    /// @dev Used for managinng of token IDs
    using Counters for Counters.Counter;
    /// @dev Used for token IDs concatenate with baseURI
    using Strings for uint256;

    Counters.Counter private totalAmount;

    /// @dev Roles for managing some functions
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    /// @dev Constant for checking 'supportInterface'
    bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;

    /// @notice Contract owner address
    address public owner;
    /// @notice Deployer contract address  
    address public factory;
    /// @notice Price in SUN for minting new tokens
    uint256 public price;
    /// @notice Fee in percent which contract owner takes for selling NFT on Trade contract
    uint256 public percentFee;
    /// @notice Decimals of 'percentFee' number, example: 25.55% in 'percentFee' would be 2555
    uint256 constant public percentDecimals = 2;
    /// @notice Base URI which is common for all tokens URI
    string public baseURI;

    /// @dev Mapping which contains all existing token IDs
    mapping(uint256 => string) private _tokenURIs;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address owner_,
        uint256 price_,
        uint256 percentFee_,
        uint256 amount_
    ) TRC721(name_, symbol_) {
        owner = owner_;
        factory = msg.sender;
        price = price_;
        percentFee = percentFee_;
        baseURI = baseURI_;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(DEFAULT_ADMIN_ROLE, owner_);
        grantRole(ADMIN_ROLE, owner_);
        grantRole(MINTER_ROLE, owner_);

        /// A loop for minting inital amount of tokens
        for (uint256 i = 0; i < amount_; i++) {
            _safeMint(owner_, totalAmount.current());
            totalAmount.increment();
        }
    }

    /// @notice Mints new 'amount' tokens to 'to' address, available only for MINTER_ROLE
    /// @param to Address you want to mint new tokens
    /// @param amount Amount of tokens you want to create
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(to, totalAmount.current());
            totalAmount.increment();
        }
    }

    /// @notice Returns total amount of minted tokens
    function totalSupply() public view returns (uint256) {
        return totalAmount.current();
    }

    /// @notice Mints tokens to msg.sender for paid TRX, which must be more then 'price' value
    /// @param recepient Address which get new minted tokens
    function mintForTRX(address recepient) external payable {
        require(msg.value >= price, "Unsufficient TRX value");

        uint256 amount = msg.value / price;

        (bool success, ) = owner.call{value: msg.value}("");
        require(success, "Can not send TRX to contract`s owner");

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(recepient, totalAmount.current());
            totalAmount.increment();
        }
    }

    /// @notice Returns URL of token`s metadata
    /// @param tokenId Id of token you want to get URL
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        _requireMinted(tokenId);

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    /// @notice Changes price for 'mintForTRX' function, available only for ADMIN_ROLE
    function changePrice(uint256 _price) external onlyRole(ADMIN_ROLE) {
        price = _price;
    }

    /// @notice Changes fee percent for NFT contract owner, available only for ADMIN_ROLE
    function changeFeePercent(uint256 _percentFee) external onlyRole(ADMIN_ROLE) {
        require(_percentFee > 0, "Fee must be more then 0 %");
        require(_percentFee <= 10000, "Maximum fee is 100,00 %");
        percentFee = _percentFee;
    }

    /// @notice Changes baseURI for all tokens, available only for ADMIN_ROLE
    function setBaseURI(string memory _baseURI) external onlyRole(ADMIN_ROLE) {
        baseURI = _baseURI;
    }

    /// @dev Checks for existed token ID
    function _requireMinted(uint256 tokenId) internal view {
        require(_exists(tokenId), "TRC721: invalid token ID");
    }

    /// @notice Returns array of token IDs owned by 'account' address
    /// @param account Address you want to get token IDs
    function getAllIds(address account) external view returns(uint256[] memory) {
        uint256 accountBalance = balanceOf(account);
        uint256 totalIds = totalAmount.current();
        uint256[] memory idArray = new uint256[](accountBalance);
        uint256 idArrayIndex = 0;

        for (uint256 i = 0; i < totalIds; i++) {
            if (ownerOf(i) == account) {
                idArray[idArrayIndex] = i;
                idArrayIndex++;
            }
        }

        return idArray;
    }
    
    /// @dev See {ITRC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(TRC721, AccessControl)
        returns (bool)
    {
        return
            interfaceId == _INTERFACE_ID_FEES ||
            AccessControl.supportsInterface(interfaceId);
    }
    
    /**
     * @dev Hook that is called before any token transfer. This includes minting.
     *
     * First checks Trade contract address from NFTFactory deployer contract
     *
     * Calling conditions:
     * 
     * To the Trade contract for selling
     * From the Trade contract for buying
     * From the owner of contract
     * From zero address for minting
     * 
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId);

        (, bytes memory result) = factory.call(abi.encodeWithSignature("tradeAddress()"));

        address tradeAddress = abi.decode(result, (address));
        require(tradeAddress != address(0), "Trading is not avaliable now");

        if(from != tradeAddress && to != tradeAddress && from != owner && from != address(0)) {
            revert();
        }
    }
}
