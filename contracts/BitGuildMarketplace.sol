pragma solidity ^0.4.22;

import "./BitGuildToken.sol";
import "./BitGuildAccessAdmin.sol";
import "./BitGuildWhitelist.sol";
import "./BitGuildFeeProvider.sol";
import "./SafeMath.sol";
import "./ERC721.sol";
import "./Seriality.sol";


// @title ERC-721 Non-Fungible Token Standard
// @dev Include interface for both new and old functions
interface ERC721TokenReceiver {
	function onERC721Received(address _from, uint256 _tokenId, bytes data) external returns(bytes4);
	function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes data) external returns(bytes4);
}

/*
 * @title BitGuildMarketplace
 * @dev: Marketplace smart contract for BitGuild.com
 */
contract BitGuildMarketplace is BitGuildAccessAdmin, Seriality {
    using SafeMath for uint256;

    //from zepellin ERC721Receiver.sol
    //old version
    bytes4 constant ERC721_RECEIVED_OLD = 0xf0b9e5ba;
    //new version with operator
    bytes4 constant ERC721_RECEIVED = 0x150b7a02;

    // BitGuild Contracts
    // BitGuildToken public PLAT = BitGuildToken(0x7E43581b19ab509BCF9397a2eFd1ab10233f27dE); // Main Net
    // BitGuildWhitelist public Whitelist = BitGuildWhitelist(); // Main Net
    // BitGuildFeeProvide public FeeProvider = BitGuildFeeProvider(); // Main Net
    BitGuildToken public PLAT = BitGuildToken(0x0F2698b7605fE937933538387b3d6Fec9211477d); // Rinkeby
    BitGuildWhitelist public Whitelist = BitGuildWhitelist(0x72b93A4943eF4f658648e27D64e9e3B8cDF520a6); // Rinkeby
    BitGuildFeeProvider public FeeProvider = BitGuildFeeProvider(0x47831668C08d635037ABfc9CF2B75Bd7658C7633); // Rinkeby

    // TODO: add function to modify this length or move this to a separate contract
    uint public defaultExpiry = 7 days;   // default expiry 7 days

    enum Currencies { PLAT, ETH }
    struct Listing {
        Currencies currency;    // ETH or PLAT
        address seller;         // seller address
        address token;          // token contract
        uint tokenId;           // token id
        uint price;             // Big number in ETH or PLAT
        uint createdAt;         // timestamp
        uint expiry;            // createdAt + defaultExpiry
    }

    mapping(bytes32 => Listing) public listings;

    event LogListingCreated(
        address _seller,
        address _contract,
        uint _tokenId,
        uint _createdAt,
        uint _expiry
    );

    event LogListingExtended(
        address _seller,
        address _contract,
        uint _tokenId,
        uint _createdAt,
        uint _expiry
    );

    event LogItemSold(
        address _buyer,
        address _seller,
        address _contract,
        uint _tokenId,
        uint _price,
        Currencies _currency,
        uint _soldAt
    );

    event LogItemWithdrawn(
        address _seller,
        address _contract,
        uint _tokenId,
        uint _withdrawnAt
    );

    event LogItemExtended(
        address _contract,
        uint _tokenId,
        uint _modifiedAt,
        uint _expiry
    );

    // modifier isTokenOwner(address _contract, uint _tokenId) {
    //     ERC721 gameToken = ERC721(_contract);
    //     require(
    //         gameToken.ownerOf(_tokenId) == msg.sender,
    //         "Seller does not own the token."
    //     );
    //     _;
    // }

    // modifier isItemSeller(address _contract, uint _tokenId) {
    //     require(
    //         itemIdToSeller[_itemId] == msg.sender,
    //         "Not item seller."
    //     );
    //     _;
    // }

    // modifier isPriceValid(uint _price) {
    //     require(
    //         _price > 0,
    //         "Invalid price."
    //     );
    //     _;
    // }

    // modifier doPricesMatchETH(uint _itemId) {
    //     require(
    //         itemIdToETH[_itemId] == msg.value,
    //         "Mismatched ETH prices."
    //     );
    //     _;
    // }

    // modifier doPricesMatchPLAT(uint _itemId, uint _price) {
    //     require(
    //         itemIdToPLAT[_itemId] == _price,
    //         "Mismatched PLAT prices."
    //     );
    //     _;
    // }

    // modifier isPLAT() {
    //     // Make sure it is sent from BitGuildToken
    //     require(
    //         msg.sender == address(PLAT),
    //         "Unauthorized PLAT contract address."
    //     );
    //     _;
    // }

    // @dev fall back function
    function () external payable {
        revert();
    }

    // ===========================================
    // Fee functions
    // ===========================================
    function getFee(uint _price) public view returns(uint percent, uint fee) {
        (percent, fee) = FeeProvider.getFee(_price);
    }

    function getFee(uint _price, address _buyer, address _seller, address _token) public view returns(uint percent, uint fee) {
        (percent, fee) = FeeProvider.getFee(_price, _buyer, _seller, _token);
    }

    // ===========================================
    // Seller Functions
    // ===========================================

    // Deposit Item
    // @dev deprecated callback (did not handle operator). included to support older contracts
    function onERC721Received(address _from, uint _tokenId, bytes _extraData)
        external
        returns(bytes4)
    {
        _deposit(_from, msg.sender, _tokenId, _extraData);
        return ERC721_RECEIVED_OLD;
    }

    // @dev expected callback (include operator)
    function onERC721Received(address _operator, address _from, uint _tokenId, bytes _extraData)
        external
        returns(bytes4)
    {
        _deposit(_from, msg.sender, _tokenId, _extraData);
        return ERC721_RECEIVED;
    }

    // @dev Withdraw item from marketplace back to seller
    // @param _contract whitelisted game contract
    // @param _tokenId  tokenId
    function extendItem(address _contract, uint _tokenId) public returns(bool) {
        bytes32 hash = _getHashKey(_contract, _tokenId);
        address seller = listings[hash].seller;
        require(
            Whitelist.isWhitelisted(_contract),
            "Contract not in whitelist."
        );

        require(
            seller == msg.sender,
            "Only seller can withdraw listing."
        );

        listings[hash].expiry += defaultExpiry;

        emit LogListingExtended(
            seller,
            _contract,
            _tokenId,
            listings[hash].createdAt,
            listings[hash].expiry
        );

        return true;
    }

    // @dev Withdraw item from marketplace back to seller
    // @param _contract whitelisted game contract
    // @param _tokenId  tokenId
    function withdrawItem(address _contract, uint _tokenId) public returns(bool) {
        // TODO: validate _contract and _tokenId?
        bytes32 hash = _getHashKey(_contract, _tokenId);
        address seller = listings[hash].seller;

        require(
            Whitelist.isWhitelisted(_contract),
            "Contract not in whitelist."
        );

        require(
            seller == msg.sender,
            "Only seller can withdraw listing."
        );

        // Transfer item back to seller
        ERC721 gameToken = ERC721(_contract);
        gameToken.safeTransferFrom(this, seller, _tokenId);

        emit LogItemWithdrawn(seller, _contract, _tokenId, now);

        // remove listing
        _delist(hash);

        return true;
    }

    // ===========================================
    // Purchase Item
    // ===========================================
    // TODO: add fee integration
    // function buyWithETH(uint _itemId)
    //     public
    //     onlyWhitelisted(itemIdToContract[_itemId])
    //     doPricesMatchETH(_itemId)
    //     payable
    //     returns(bool success)
    // {
    //     // Check for valid item Id
    //     _isValidItemId(_itemId);

    //     // Check if item is available
    //     _isItemAvailable(_itemId);
    //     // TODO: handle fees

    //     // Transfer ETH to service contract
    //     require(
    //         msg.sender.send(msg.value),
    //         "ETH transfer failed."
    //     );

    //     // Transfer item token to buyer
    //     _safeTransferToken(_itemId);

    //     // Update mappings
    //     address seller = itemIdToSeller[_itemId];
    //     itemIdToSeller[_itemId] = address(0);     // Mark item unavailable

    //     // Emit event
    //     emit ItemSold(msg.sender, seller, _itemId, msg.value, 0);
    //     return true;
    // }

    // Buy with PLAT requires calling BitGuildToken contract, then redirect here
    // _extraData: address _gameContract, uint _tokenId
    function receiveApproval(address _buyer, uint _value, BitGuildToken _PLAT, bytes _extraData)
        public

        address token;
        uint tokenId;
        (token, tokenId) = _decodeBuyData(_extraData);
        bytes32 hash = _getHashKey(token, tokenId);
        address seller = listings[hash].seller;
        uint price = listings[hash].price;
        Currencies currency = listings[hash].currency;

        uint fee;
        (,fee) = getFee(_value, _buyer, seller, token);

        // TODO: add validation back
        // require(
        //     Currencies(listings[hash].currency) == Currencies.PLAT,
        //     "Must be purchased with PLAT."
        // );

        // require(
        //     price > 0 && price == _value,
        //     "Invalid purchase price."
        // );

        // require(
        //     listings[hash].expiry > now,
        //     "Item has expired."
        // );

        // TODO: wrap require to all transfers
        // Transfer PLAT to marketplace contract
        _PLAT.transferFrom(_buyer, address(this), _value);
        // Transfer item token to buyer
        ERC721 gameToken = ERC721(token);
        gameToken.safeTransferFrom(this, _buyer, tokenId);
        // // Transfer Balance - Fee to seller
        // _PLAT.transferFrom(address(this), seller, _value - fee);

        // delist item
        _delist(hash);

        // Emit event
        emit LogItemSold(_buyer, seller, token, tokenId, _value, currency, now);
    }

    // ===========================================
    // Admin Functions
    // ===========================================
    // @dev Admin function: withdraw ETH balance
    function withdrawETH() public onlyOwner payable {
        address(this).transfer(msg.value);
    }

    // @dev Admin function: withdraw PLAT balance
    function withdrawPLAT() public onlyOwner payable {
        uint balance = PLAT.balanceOf(this);
        PLAT.transfer(msg.sender, balance);
    }

    // ===========================================
    // Internal Functions
    // ===========================================
    function _delist(bytes32 hash) internal {
        // remove listing
        listings[hash].currency = Currencies(0);
        listings[hash].seller = address(0);
        listings[hash].token = address(0);
        listings[hash].tokenId = 0;
        listings[hash].price = 0;
        listings[hash].createdAt = 0;
        listings[hash].expiry = 0;
    }
    function _getHashKey(address _contract, uint _tokenId) internal pure returns(bytes32 key) {
        key = keccak256(abi.encodePacked(_contract, _tokenId));
    }

    function _newListing(address _seller, address _contract, uint _tokenId, uint _price, uint _currency) internal {
        bytes32 hash = _getHashKey(_contract, _tokenId);
        uint createdAt = now;
        uint expiry = now + defaultExpiry;
        listings[hash].currency = Currencies(_currency);
        listings[hash].seller = _seller;
        listings[hash].token = _contract;
        listings[hash].tokenId = _tokenId;
        listings[hash].price = _price;
        listings[hash].createdAt = createdAt;
        listings[hash].expiry = expiry;

        lastTx.currency = Currencies(_currency);
        lastTx.seller = _seller;
        lastTx.token = _contract;
        lastTx.tokenId = _tokenId;
        lastTx.price = _price;
        lastTx.createdAt = createdAt;
        lastTx.expiry = expiry;

        emit LogListingCreated(_seller, _contract, _tokenId, createdAt, expiry);
    }

    // @dev unpack _extraData and log info
    // @param _extraData packed bytes of (uint _price, uint _currency)
    function _deposit(address _seller, address _contract, uint _tokenId, bytes _extraData) internal {
        require(
            Whitelist.isWhitelisted(_contract),
            "Contract not in whitelist."
        );

        uint price;
        uint currency;
        (currency, price) = _decodePriceData(_extraData);

        _newListing(_seller, _contract, _tokenId, price, currency);
    }

    function _decodePriceData(bytes _extraData) internal pure returns(uint _currency, uint _price) {
        // Deserialize _extraData
        uint256 offset = 64;
        _price = bytesToUint256(offset, _extraData);
        offset -= sizeOfUint(256);
        _currency = bytesToUint256(offset, _extraData);
    }

    function _decodeBuyData(bytes _extraData) internal pure returns(address _contract, uint _tokenId) {
        // Deserialize _extraData
        uint256 offset = 64;
        _tokenId = bytesToUint256(offset, _extraData);
        offset -= sizeOfUint(256);
        _contract = bytesToAddress(offset, _extraData);
    }

    // function _isValidItemId(uint _itemId) private view {
    //     require(
    //         _itemId > 0 && _itemId <= currentItemId,
    //         "Invalid item id."
    //     );
    // }

    // function _isItemAvailable(uint _itemId) private view {
    //     // Check if item still available
    //     require(
    //         itemIdToSeller[_itemId] != address(0),
    //         "Item is not available."
    //     );

    //     // Check if token still in this contract
    //     address _contract = itemIdToContract[_itemId];
    //     uint _tokenId = itemIdToTokenId[_itemId];
    //     ERC721 gameToken = ERC721(_contract);
    //     require(
    //         gameToken.ownerOf(_tokenId) == address(this),
    //         "Item is not on the exchange."
    //     );
    // }
}
