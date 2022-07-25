// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title Trade contract for trading NFT from TRC721 which was deployed from NFTFactory
/// @author AkylbekAD
/// @notice This is the only marketplace where TRC721 from NFTFactory NFTs could be traded

import "./ITRC721.sol";

contract Trade {
    /// @dev Contains all data types of each order
    struct Order {
        uint256 priceSUN;
        uint256 percentFee;
        address seller;
        address buyer;
        bool sellerAccepted;
    }

    /// @dev Contains all data types of each auction
    struct Auction {
        uint256 bestPrice;
        uint256 percentFee;
        uint256 deadline;
        address bestBider;
        address seller;
    }

    /// @dev Address of contract owner
    address public owner;

    /// @notice Amount of decimals of fee percents
    uint256 constant public percentDecimals = 2;

    /// @notice Minimal amount of time for each auction
    uint256 public minimumAuctionTime = 2 days;

    /// @dev Some constants for non-Reetrancy modifier
    uint256 private _status;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    /// @notice Contains and returns NFT orders structs
    mapping(address => mapping(uint256 => Order)) public NFTOrders;
    /// @notice Contains and returns NFT auction structs
    mapping(address => mapping(uint256 => Auction)) public NFTAuctions;

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
    event AuctionStarted(
        address indexed NFTAddress,
        uint256 indexed tokenID,
        uint256 indexed priceSUN,
        address seller
    );
    event BibDone(
        address indexed NFTAddress,
        uint256 indexed tokenID,
        uint256 indexed bestBid,
        address bestBider
    );
    event AuctionEnded(
        address indexed NFTAddress,
        uint256 indexed tokenID,
        uint256 indexed bestPrice,
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

    /**
     * @notice First you need to approve token transfer to Trade contract.
     *        Then you can add an order for selling you approved NFT
     * @param _NFTAddress TRC721 contract address
     * @param _tokenID NFT token ID you want to sell
     * @param _priceSUN Price value in SUN for NFT order, must be equal or more 10000 
     * @dev Function makes an call to '_NFTAddress' contract to get 'percentFee' value 
     *      to pay fee to owner
     */
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
        require(_priceSUN >= 10000, "Minumal price for sale is 10000 SUN");

        (, bytes memory result ) = _NFTAddress.call(abi.encodeWithSignature("percentFee()"));
        uint256 _percentFee = abi.decode(result, (uint256));

        NFTOrders[_NFTAddress][_tokenID].priceSUN = _priceSUN;
        NFTOrders[_NFTAddress][_tokenID].seller = msg.sender;
        NFTOrders[_NFTAddress][_tokenID].percentFee = _percentFee;

        emit OrderAdded(_NFTAddress, _tokenID, _priceSUN, msg.sender);

        return true;
    }

    /**
     * @notice Seller can remove an order, if it is not funded.
     * If not, seller or buyer must call 'declineOrder' to remove order
     * @param _NFTAddress TRC721 contract address
     * @param _tokenID NFT token ID you want to return
     * @dev Only seller of order can call this function
     */
    function removeOrder(address _NFTAddress, uint256 _tokenID) external {
        address seller = NFTOrders[_NFTAddress][_tokenID].seller;
        require(msg.sender == seller, "You are not an seller");
        require(
            NFTOrders[_NFTAddress][_tokenID].buyer == address(0),
            "Order is funded, funds must be returned"
        );

        ITRC721(_NFTAddress).transferFrom(address(this), seller, _tokenID);

        delete NFTOrders[_NFTAddress][_tokenID];

        emit OrderRemoved(_NFTAddress, _tokenID, seller);
    }

    /**
     * @notice Funds an order you want to redeem, function must be funded with enough TRX
     * @param _NFTAddress TRC721 contract address
     * @param _tokenID NFT token ID you want to buy
     * @dev TRX value must be equal or more then order price, buyer address must be zero
     */
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

    /**
     * @notice Seller can accept an order to be initialized, after it was funded by buyer
     * @param _NFTAddress TRC721 contract address
     * @param _tokenID NFT token ID you want to accept an order
     * @dev Only seller of order can call this function
     */
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

    /**
     * @notice Initializes token transfer to buyer, fees to NFT contract owner and reward to seller
     * @param _NFTAddress TRC721 contract address
     * @param _tokenID NFT token ID you want to initialize order
     * @dev Anyone can call this function, reverts if any 'success' value returns false
     */
    function initializeOrder(address _NFTAddress, uint256 _tokenID)
        external
        nonReentrant
    {
        Order storage order = NFTOrders[_NFTAddress][_tokenID];
        require(order.sellerAccepted, "Seller didnt accept a trade");
        require(order.buyer != address(0), "Noone redeems an order");

        uint256 fee = (order.priceSUN * order.percentFee) / (100 ** percentDecimals);
        uint256 reward = order.priceSUN - fee;

        (, bytes memory result) = _NFTAddress.call(abi.encodeWithSignature("owner()"));
        address nftContractOwner = abi.decode(result, (address));
        
        (bool success1, ) = nftContractOwner.call{value: fee}("");
        require(success1, "Can not send TRX to NFT contract owner");

        (bool success2, ) = order.seller.call{value: reward}("");
        require(success2, "Can not send TRX to seller");

        ITRC721(_NFTAddress).transferFrom(address(this), order.buyer, _tokenID);

        delete NFTOrders[_NFTAddress][_tokenID];

        emit OrderInitilized(_NFTAddress, _tokenID, order.seller, order.buyer);
    }

    /**
     * @notice Returns funds to order buyer, can only be called by order seller or buyer
     * @param _NFTAddress TRC721 contract address
     * @param _tokenID NFT token ID you want to unfund
     * @dev Reverts if 'success' value returns false
     */
    function declineOrder(address _NFTAddress, uint256 _tokenID)
        external
        nonReentrant
    {
        Order storage order = NFTOrders[_NFTAddress][_tokenID];
        require(msg.sender == order.buyer || msg.sender == order.seller, "Only seller and buyer can decline");
        require(order.buyer != address(0), "Nothing to decline");

        (bool success, ) = order.buyer.call{value: order.priceSUN}("");
        require(success, "Can not send TRX to buyer");
        
        NFTOrders[_NFTAddress][_tokenID].buyer = address(0);
        NFTOrders[_NFTAddress][_tokenID].sellerAccepted = false;

        emit DepositReturned(_NFTAddress, _tokenID, order.priceSUN, msg.sender);
    }

    /**
     * @notice Creates auction order for NFT, approved by it`s owner to Trade contract
     * @param _NFTAddress TRC721 contract address
     * @param _tokenID NFT token ID you want to sell on auction
     * @param initialPrice Start price in SUN for NFT on auction 
     * @param secondsToEnd How much seconds should be passed for auction to be ended
     * @dev Gets value of 'percentFee' from '_NFTAddress' contract
     */
    function startAuction(
        address _NFTAddress,
        uint256 _tokenID,
        uint256 initialPrice,
        uint256 secondsToEnd
    ) external {
        ITRC721(_NFTAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenID
        );
        require(initialPrice >= 10000, "Minumal price for sale is 10000 SUN");
        require(secondsToEnd >= minimumAuctionTime, "Time must be more then minimal auction time");

        (, bytes memory result ) = _NFTAddress.call(abi.encodeWithSignature("percentFee()"));
        uint256 _percentFee = abi.decode(result, (uint256));

        NFTAuctions[_NFTAddress][_tokenID].bestPrice = initialPrice;
        NFTAuctions[_NFTAddress][_tokenID].percentFee = _percentFee;
        NFTAuctions[_NFTAddress][_tokenID].seller = msg.sender;
        NFTAuctions[_NFTAddress][_tokenID].deadline = block.timestamp + secondsToEnd;

        emit AuctionStarted(_NFTAddress, _tokenID, initialPrice, msg.sender);
    }

    /**
     * @notice Makes a bid for an auction order, must be more then previous one and
     *         pays for transfering the last 'bestBidder' his 'bestBid'
     * @param _NFTAddress TRC721 contract address
     * @param _tokenID NFT token ID you want to buy
     * @dev Not reverts if can not send TRX to last 'bestBidder'
     */
    function makeBid(address _NFTAddress, uint256 _tokenID) external payable nonReentrant {
        Auction storage auction = NFTAuctions[_NFTAddress][_tokenID];

        require(auction.seller != address(0), "Token is not on sale");
        require(auction.deadline > block.timestamp, "Auction time passed");
        require(msg.value > auction.bestPrice, "Bid must be higher than previous");

        (bool success, ) = auction.bestBider.call{value: auction.bestPrice}("");

        NFTAuctions[_NFTAddress][_tokenID].bestBider = msg.sender;
        NFTAuctions[_NFTAddress][_tokenID].bestPrice = msg.value;

        emit BibDone(_NFTAddress, _tokenID, msg.value, msg.sender);
    }

    /**
     * @notice Initialize token transfer to 'bestBidder', fees to NFT contract owner and reward to seller,
     * if there is no any bids, NFT transfers back to seller
     * @param _NFTAddress TRC721 contract address
     * @param _tokenID NFT token ID you want auction get finished
     * @dev Reverts if can not send fee to NFT contract owner or reward to 'bestBidder'
     */
    function finishAuction(address _NFTAddress, uint256 _tokenID) external nonReentrant {
        Auction storage auction = NFTAuctions[_NFTAddress][_tokenID];

        require(auction.deadline < block.timestamp, "Auction time did not pass");

        if(auction.bestBider == address(0)) {
            ITRC721(_NFTAddress).safeTransferFrom(
                address(this),
                auction.seller,
                _tokenID
            );
        } else {
            uint256 fee = (auction.bestPrice * auction.percentFee) / (100 ** percentDecimals);
            uint256 reward = auction.bestPrice - fee;

            (, bytes memory result) = _NFTAddress.call(abi.encodeWithSignature("owner()"));
            address nftContractOwner = abi.decode(result, (address));

            (bool success1, ) = auction.seller.call{value: reward}("");
            require(success1, "Can not send TRX to seller");

            (bool success2, ) = nftContractOwner.call{value: fee}("");
            require(success2, "Can not send TRX to NFT contrac owner");

            ITRC721(_NFTAddress).safeTransferFrom(
                address(this),
                auction.bestBider,
                _tokenID
            );
        }

        emit AuctionEnded(_NFTAddress, _tokenID, auction.bestPrice, auction.seller, auction.bestBider);

        delete NFTAuctions[_NFTAddress][_tokenID];
    }

    function setMinimalAuctionTime(uint256 timeInSeconds) external {
        require(msg.sender == owner, "You are not an owner!");
        minimumAuctionTime = timeInSeconds;
    }

    /// @dev Needs for TRC721 token receiving
    function onTRC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onTRC721Received.selector;
    }
}

