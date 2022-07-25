// SPDX-License-Identifier: No license

pragma solidity ^0.8.0;

/// @title NFTFactory allows to create and deploy TRC721 contract on TRON
/// @author AkylbekAD
/// @notice This contract allows you predict address and deploy TRC721 non-fungble token contract

import "./NFT.sol";

contract NFTFactory {
    /// @notice The only smart-contract for trading NFTs
    address public tradeAddress;

    /// @notice Contact owner address
    address public owner;

    event Deployed(address newNFTAddress);

    /// @notice Allowing access only to Owner
    modifier onlyOwner() {
        require(msg.sender == owner, "You are not an owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice Deploys TRC721 standart non-fungble token contract and returns its address.
     *        For matching predicted address nad actually deployed one, all parameters need to be exactly the same
     * @param name Name of NFT collection
     * @param symbol Symbol of NFT collection
     * @param baseURI Basic URI for all NFTs metadata
     * @param newOwner Owner of deployed TRC721 contract
     * @param price Price in SUN for minting new tokens of collection by using function mintForTRX()
     * @param percentFee Percents of trading price which would be transfered to TRC721 owner.
     *        Percent fee must be more then 0 and less or equal to 10000, two extra zeros stands for decimals
     * @param amount Amount of tokens which would be minting after deploying
     * @param _salt Some random number which effects to the TRC721 address and used only for deploying
     * @dev Funciton uses create2 opcode for creating and deploying new TRC721 contract
     */
    function createTRC721(
        string memory name,
        string memory symbol,
        string memory baseURI,
        address newOwner,
        uint256 price,
        uint256 percentFee,
        uint256 amount,
        uint256 _salt
    ) public returns (address newNFTAddress) {
        require(percentFee > 0 && percentFee <= 10000, "Fee percent must be more than 0 and less then 10000");

        bytes32 byteSalt = bytes32(_salt);
        NFT newNFT = new NFT{salt: byteSalt}(name, symbol, baseURI, newOwner, price, percentFee, amount);
        emit Deployed(address(newNFT));

        return (address(newNFT));
    }

    /// @notice Changes Trade contract address
    /// @dev All deployed TRC721 contracts from NFTFactory apply for tradeAddress
    function setTradeAddress (address newTradeAddress) external onlyOwner {
        tradeAddress = newTradeAddress;
    }

    /**
     * @notice Returns address of potentialy deployed TRC721 contract by 'createTRC721' function on TRON
     * Feel free to fill arguments and change only '_salt' for changing whole contract address
     * @param name Name of NFT collection
     * @param symbol Symbol of NFT collection
     * @param baseURI Basic URI for all NFTs metadata
     * @param newOwner Owner of deployed TRC721 contract
     * @param price Price in SUN for minting new tokens of collection by using function mintForTRX()
     * @param percentFee Percents of trading price which would be transfered to TRC721 owner
     * @param amount Amount of tokens which would be minting after deploying
     * @param _salt Some random number which effects to the TRC721 address and used only for deploying
     */ 
    function predictAddress(
        string memory name,
        string memory symbol,
        string memory baseURI,
        address newOwner,
        uint256 price,
        uint256 percentFee,
        uint256 amount,
        uint256 _salt
    ) public view returns (address newNFTAddress) {
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
                                percentFee,
                                amount)
                            ))
            )))));
    }
}
