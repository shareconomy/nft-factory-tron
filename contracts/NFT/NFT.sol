// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./utils/Strings.sol";
import "./utils/AccessControl.sol";
import "./utils/Counters.sol";
import "./TRC721.sol";

contract NFT is TRC721, AccessControl {
    using Counters for Counters.Counter;

    Counters.Counter private totalAmount;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;

    address public owner;
    uint256 private price;

    constructor(
        string memory name_,
        string memory symbol_,
        address owner_,
        uint256 price_
    ) TRC721(name_, symbol_) {
        owner = owner_;
        price = price_;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(DEFAULT_ADMIN_ROLE, owner_);
        grantRole(ADMIN_ROLE, owner_);
        grantRole(MINTER_ROLE, owner_);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        for (uint256 i = 0; i <= amount; i++) {
            _safeMint(to, totalAmount.current());
            totalAmount.increment();
        }
    }

    function changePrice(uint256 amount) external onlyRole(ADMIN_ROLE) {
        price = amount;
    }

    function totalSupply() public view returns (uint256) {
        return totalAmount.current();
    }

    function mintForTRX(address recepient) external payable {
        require(msg.value >= getPrice(), "Unsufficient TRX value");

        uint256 amount = msg.value / getPrice();

        (bool success, ) = owner.call{value: msg.value}("");
        require(success, "Can not send TRX to contract owner");

        for (uint256 i = 1; i <= amount; i++) {
            _safeMint(recepient, totalAmount.current());
            totalAmount.increment();
        }
    }

    function getPrice() public view returns (uint256) {
        return price;
    }

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
}
