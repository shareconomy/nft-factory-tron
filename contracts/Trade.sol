// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./NFT/interfaces/ITRC721.sol";

contract Trade {
    struct Order {
        uint256 priceSUN;
        address seller;
        address buyer;
        bool sellerAccepted;
    }

    address public owner;

    uint256 private _status;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    mapping(address => mapping(uint256 => Order)) public NFTOrders;

    event OrderAdded(
        address indexed NFTAddress,
        uint256 indexed tokenID,
        uint256 indexed priceSUN,
        address seller
    );
    event OrderRedeemed(
        address indexed NFTAddress,
        uint256 indexed tokenID,
        address indexed buyer
    );
    event OrderRemoved(
        address indexed NFTAddress,
        uint256 indexed tokenID,
        address seller
    );

    event DepositReturned(
        address indexed NFTAddress,
        uint256 indexed tokenID,
        uint256 indexed priceSUN,
        address buyer
    );
    event SellerAccepted(
        address indexed NFTAddress,
        uint256 indexed tokenID,
        bool indexed accepted
    );
    event OrderInitilized(
        address indexed NFTAddress,
        uint256 indexed tokenID,
        address seller,
        address buyer
    );

    /* Prevent a contract function from being reentrant-called. */
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
        _;
        // By storing the original value once again, a refund is triggered
        _status = _NOT_ENTERED;
    }

    constructor() {
        owner = msg.sender;
        _status = _NOT_ENTERED;
    }

    function addOrder(
        address _NFTAddress,
        uint256 _tokenID,
        uint256 _priceSUN
    ) external returns (bool isOrderAdded) {
        ITRC721(_NFTAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenID
        );

        NFTOrders[_NFTAddress][_tokenID].priceSUN = _priceSUN;
        NFTOrders[_NFTAddress][_tokenID].seller = msg.sender;

        emit OrderAdded(_NFTAddress, _tokenID, _priceSUN, msg.sender);

        return true;
    }

    function removeOrder(address _NFTAddress, uint256 _tokenID) external {
        address seller = NFTOrders[_NFTAddress][_tokenID].seller;
        require(msg.sender == seller, "You are not an owner");
        require(
            NFTOrders[_NFTAddress][_tokenID].buyer == address(0),
            "Order is funded, funds must be returned"
        );

        ITRC721(_NFTAddress).transferFrom(address(this), seller, _tokenID);

        delete NFTOrders[_NFTAddress][_tokenID];

        emit OrderRemoved(_NFTAddress, _tokenID, seller);
    }

    function redeemOrder(address _NFTAddress, uint256 _tokenID)
        external
        payable
        returns (bool success)
    {
        require(
            msg.value >= NFTOrders[_NFTAddress][_tokenID].priceSUN,
            "Insufficient funds to redeem"
        );
        require(
            NFTOrders[_NFTAddress][_tokenID].buyer == address(0),
            "Order has been funded"
        );

        NFTOrders[_NFTAddress][_tokenID].buyer = msg.sender;

        emit OrderRedeemed(_NFTAddress, _tokenID, msg.sender);

        return true;
    }

    function acceptOrder(
        address _NFTAddress,
        uint256 _tokenID,
        bool isAccepted
    ) external nonReentrant {
        Order storage order = NFTOrders[_NFTAddress][_tokenID];
        require(msg.sender == order.seller, "You are not a seller");
        require(order.buyer != address(0), "Noone redeems an order");

        if (isAccepted) {
            order.sellerAccepted = true;
        } else {
            (bool success, ) = order.buyer.call{value: order.priceSUN}("");
            require(success, "Can not send TRX to buyer");

            order.buyer = address(0);
        }

        emit SellerAccepted(_NFTAddress, _tokenID, isAccepted);
    }

    function initilizeOrder(address _NFTAddress, uint256 _tokenID)
        external
        nonReentrant
    {
        Order storage order = NFTOrders[_NFTAddress][_tokenID];
        require(order.sellerAccepted, "Seller didnt accept a trade");
        require(order.buyer != address(0), "Noone redeems an order");

        (bool success, ) = order.seller.call{value: order.priceSUN}("");
        require(success, "Can not send TRX to seller");

        ITRC721(_NFTAddress).transferFrom(address(this), order.buyer, _tokenID);

        delete NFTOrders[_NFTAddress][_tokenID];

        emit OrderInitilized(_NFTAddress, _tokenID, order.seller, order.buyer);
    }

    function declineOrder(address _NFTAddress, uint256 _tokenID)
        external
        nonReentrant
    {
        Order storage order = NFTOrders[_NFTAddress][_tokenID];
        require(msg.sender == order.buyer || msg.sender == order.seller, "Only seller and buyer can decline");
        require(order.buyer != address(0), "Nothing to decline");

        (bool success, ) = order.seller.call{value: order.priceSUN}("");
        require(success, "Can not send TRX to buyer");
        
        NFTOrders[_NFTAddress][_tokenID].buyer = address(0);
        NFTOrders[_NFTAddress][_tokenID].sellerAccepted = false;

        emit DepositReturned(_NFTAddress, _tokenID, order.priceSUN, msg.sender);
    }

    function onTRC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onTRC721Received.selector;
    }
}
