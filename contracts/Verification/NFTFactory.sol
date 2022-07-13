// SPDX-License-Identifier: No license

pragma solidity ^0.8.0;

import "./NFT.sol";

contract NFTFactory {
    event Deployed(address newNFTaddress);

    function createTRC721(
        string memory name,
        string memory symbol,
        string memory baseURI,
        address owner,
        uint256 price,
        uint256 amount,
        uint256 _salt
    ) public returns (address newNFTaddress) {
        bytes32 byteSalt = bytes32(_salt);
        NFT newNFT = new NFT{salt: byteSalt}(name, symbol, baseURI, owner, price, amount);
        emit Deployed(address(newNFT));

        return (address(newNFT));
    }

    function predictAddress(
        string memory name,
        string memory symbol,
        string memory baseURI,
        address owner,
        uint256 price,
        uint256 amount,
        uint256 _salt
    ) public view returns (address newNFTaddress) {
        return
            address(
                uint160(
                    uint(
                        keccak256(
                            abi.encodePacked(
                                bytes1(0x41),
                                address(this),
                                _salt,
                                keccak256(
                                    abi.encodePacked(
                                        type(NFT).creationCode,
                                        name,
                                        symbol,
                                        baseURI,
                                        owner,
                                        price,
                                        amount
                                    )
                                )
                            )
                        )
                    )
                )
            );
    }
}
