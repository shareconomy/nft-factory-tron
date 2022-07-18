// SPDX-License-Identifier: No license

pragma solidity ^0.8.0;

import "./NFT.sol";

contract NFTFactory {
    address tradeAddress;
    address public owner;

    event Deployed(address newNFTaddress);

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not an owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createTRC721(
        string memory name,
        string memory symbol,
        string memory baseURI,
        address newOwner,
        uint256 price,
        uint256 amount,
        uint256 _salt
    ) public returns (address newNFTaddress) {
        bytes32 byteSalt = bytes32(_salt);
        NFT newNFT = new NFT{salt: byteSalt}(name, symbol, baseURI, newOwner, price, amount);
        emit Deployed(address(newNFT));

        return (address(newNFT));
    }

    function setTradeAddress (address newTradeAddress) external onlyOwner {
        tradeAddress = newTradeAddress;
    }

    function getTradeAddress() external view returns(address) {
        return tradeAddress;
    }

    function predictAddress(
        string memory name,
        string memory symbol,
        string memory baseURI,
        address newOwner,
        uint256 price,
        uint256 amount,
        uint256 _salt
    ) public view returns (address newNFTaddress) {
        return
            address(uint160(uint(keccak256(abi.encodePacked(
                            bytes1(0x41),
                            address(this),
                            bytes32(_salt),
                            keccak256(abi.encodePacked(
                                type(NFT).creationCode,
                                abi.encode(
                                name,
                                symbol,
                                baseURI,
                                newOwner,
                                price,
                                amount)
                            ))
            )))));
    }
}
