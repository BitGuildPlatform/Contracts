pragma solidity ^0.4.22;

import "./BitGuildToken.sol";
import "./BitGuildAccessAdmin.sol";
import "./BitGuildWhitelist.sol";
import "./BitGuildFeeOracle.sol";
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
    // BitGuildToken public token = BitGuildToken(0x7E43581b19ab509BCF9397a2eFd1ab10233f27dE); // Main Net
    // BitGuildWhitelist public whitelist = BitGuildWhitelist(); // Main Net
    BitGuildToken public PLAT = BitGuildToken(0x0F2698b7605fE937933538387b3d6Fec9211477d); // Rinkeby
    BitGuildWhitelist public Whitelist = BitGuildWhitelist(0x72b93A4943eF4f658648e27D64e9e3B8cDF520a6); // Rinkeby

    // TODO: add function to modify this length or move this to a separate contract
    uint public defaultExpiry = 7 days;   // default expiry 7 days

    // TODO: add extend function
    struct Listing {
        address seller;     // seller address
        uint pirce;         // Big number in ETH or PLAT
        uint currency;      // 0: ETH, 1: PLAT
        uint createdAt;     // timestamp
        uint expiry;        // createdAt + defaultExpiry
    }

    uint public numListings = 0;
    mapping(uint => Listing) public listings;

    mapping(address => mapping(uint => uint)) public listingIndex;

    event LogListingCreated(
        address _seller,
        address _contract,
        uint _tokenId,
        uint _createdAt,
        uint expiry
    );

    event LogItemSold(
        address _buyer,
        address _seller,
        address _contract,
        uint _tokenId,
        uint _price,
        uint _currency,
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
    function withdrawItem(address _contract, uint _tokenId) public returns(bool) {
        uint index = listingIndex[_contract][_tokenId];
        require(
            index > 0,
            "Listing not found."
        );
        Listing memory listing = listings[index];
        address seller = listing.seller;

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
        delete listings[index];
        listingIndex[_contract][_tokenId] = 0;

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

    // // Buy with PLAT requires calling BitGuildToken contract, then redirect here
    // function receiveApproval(address _sender, uint _value, bytes _extraData)
    //     public
    //     isPLAT
    //     doPricesMatchPLAT(_itemId, _value)
    //     returns(bool success)
    // {
    //     require(
    //         _extraData.length != 0,
    //         "No extraData provided."
    //     );

    //     // TODO: handle fees

    //     // convert tokenId back to uint
    //     uint _itemId = _bytesToUint(_extraData);

    //     // Check for valid item Id
    //     _isValidItemId(_itemId);

    //     // Check if item is available
    //     _isItemAvailable(_itemId);

    //     // check if set has price and has correct price
    //     require(
    //         itemIdToPLAT[_itemId] == _value,
    //         "Invalid PLAT price."
    //     );

    //     // Transfer item token to buyer
    //     _safeTransferToken(_itemId);

    //     // Transfer PLAT to service contract
    //     require(
    //         PLAT.transferFrom(_sender, address(this), _value),
    //         "Approved PLAT transfer failed."
    //     );

    //     // Update mappings
    //     address seller = itemIdToSeller[_itemId];
    //     itemIdToSeller[_itemId] = address(0);     // Mark item unavailable

    //     // Emit event
    //     emit ItemSold(_sender, seller, _itemId, 0, _value);
    //     return true;
    // }

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
    function _newListing(address _seller, address _contract, uint _tokenId, uint _price, uint _currency) internal returns(uint id) {
        id = numListings++;
        uint createdAt = now;
        uint expiry = now + defaultExpiry;
        listings[id] = Listing(_seller, _price, _currency, createdAt, expiry);

        emit LogListingCreated(_seller, _contract, _tokenId, createdAt, expiry);
    }

    // @dev unpack _extraData and log info
    // @param _extraData packed bytes of (uint _price, uint _currency)
    function _deposit(address _seller, address _contract, uint _tokenId, bytes _extraData) internal returns(uint newListingId) {
        require(
            Whitelist.isWhitelisted(_contract),
            "Contract not in whitelist."
        );

        // Deserialize _extraData
        uint256 offset = sizeOfUint(256) * 2;
        uint256 price = bytesToUint256(offset, _extraData);
        offset -= sizeOfUint(256);
        uint256 currency = bytesToUint256(offset, _extraData);

        newListingId = _newListing(_seller, _contract, _tokenId, price, currency);
    }
    // @dev transfer token from seller to this contract. all checks are done before calling this
    // function _safeDeposit(address _from, uint _tokenId, bytes _extraData) private {
    //     uint price = _bytesToUint(_extraData);
    //     require(price > 0);                  // make sure price is valid

    //     // Update mappings
    //     itemIdToContract[currentItemId] = msg.sender;   // game contract
    //     itemIdToSeller[currentItemId] = _from;     // 
    //     itemIdToTokenId[currentItemId] = _tokenId;
    //     uint createdAt = now;
    //     uint expiry = createdAt + defaultExpiry;
    //     itemIdToCreatedAt[currentItemId] = createdAt;
    //     itemIdToPLAT[currentItemId] = price;
    //     // Emit event
    //     emit ItemDeposited(msg.sender, currentItemId, createdAt, expiry);

    //     // Update item count
    //     currentItemId = currentItemId.add(1);
    // }

    // @dev safe transfer token to buyer. all checks are done before calling this.
    // function _safeTransferToken(uint _itemId) private {
    //     // Transfer item token to buyer
    //     address _contract = itemIdToContract[_itemId];
    //     uint _tokenId = itemIdToTokenId[_itemId];

    //     ERC721 _ERC721contract = ERC721(_contract);
    //     _ERC721contract.transferFrom(this, msg.sender, _tokenId);
    // }

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

    // @dev helper function to convert bytes back to uint256
    // function _bytesToUint(bytes _b) private pure returns(uint256) {
    //     uint256 number;
    //     for (uint i=0; i < _b.length; i++) {
    //         number = number + uint(_b[i]) * (2**(8 * (_b.length - (i+1))));
    //     }
    //     return number;
    // }
}
