pragma solidity ^0.4.22;

import "./BitGuildToken.sol";
import "./BitGuildAccessAdmin.sol";
import "./BitGuildWhitelist.sol";
import "./BitGuildFeeProvider.sol";
import "./SafeMath.sol";
import "./ERC721.sol";


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
contract BitGuildMarketplace is BitGuildAccessAdmin {
    using SafeMath for uint256;

    // Callback values from zepellin ERC721Receiver.sol
    // Old ver: bytes4(keccak256("onERC721Received(address,uint256,bytes)")) = 0xf0b9e5ba;
    bytes4 constant ERC721_RECEIVED_OLD = 0xf0b9e5ba;
    // New ver w/ operator: bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")) = 0xf0b9e5ba;
    bytes4 constant ERC721_RECEIVED = 0x150b7a02;

    // BitGuild Contracts
    // BitGuildToken public PLAT = BitGuildToken(0x7E43581b19ab509BCF9397a2eFd1ab10233f27dE); // Main Net
    // BitGuildWhitelist public Whitelist = BitGuildWhitelist(); // Main Net
    // BitGuildFeeProvide public FeeProvider = BitGuildFeeProvider(); // Main Net
    BitGuildToken public PLAT = BitGuildToken(0x0F2698b7605fE937933538387b3d6Fec9211477d); // Rinkeby
    BitGuildWhitelist public Whitelist = BitGuildWhitelist(0x72b93A4943eF4f658648e27D64e9e3B8cDF520a6); // Rinkeby
    BitGuildFeeProvider public FeeProvider = BitGuildFeeProvider(0x9bE88C776299795A4996D351215274F3f1d84100); // Rinkeby

    uint public defaultExpiry = 7 days;             // default expiry is 7 days
    bool public allowWithdrawBeforeExpiry = false;  // allow withdraw listing before expiry? default is false

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

    event LogListingCreated(address _seller, address _contract, uint _tokenId, uint _createdAt, uint _expiry);
    event LogListingExtended(address _seller, address _contract, uint _tokenId, uint _createdAt, uint _expiry);
    event LogItemSold(address _buyer, address _seller, address _contract, uint _tokenId, uint _price, Currencies _currency, uint _soldAt);
    event LogItemWithdrawn(address _seller, address _contract, uint _tokenId, uint _withdrawnAt);
    event LogItemExtended(address _contract, uint _tokenId, uint _modifiedAt, uint _expiry);

    modifier onlyWhitelisted(address _contract) {
        require(Whitelist.isWhitelisted(_contract), "Contract not in whitelist.");
        _;
    }

    // @dev fall back function
    function () external payable {
        revert();
    }

    // @dev Retrieve hashkey to view listing
    function getHashKey(address _contract, uint _tokenId) public pure returns(bytes32 key) {
        key = _getHashKey(_contract, _tokenId);
    }

    // ===========================================
    // Fee functions (from fee provider contract)
    // ===========================================
    // @dev get default fee
    function getFee(uint _price) public view returns(uint percent, uint fee) {
        (percent, fee) = FeeProvider.getFee(_price);
    }

    // @dev get custom fees
    function getFee(uint _price, address _buyer, address _seller, address _token) public view returns(uint percent, uint fee) {
        (percent, fee) = FeeProvider.getFee(_price, _buyer, _seller, _token);
    }

    // ===========================================
    // Seller Functions
    // ===========================================
    // Deposit Item
    // @dev deprecated callback (did not handle operator). added to support older contracts
    function onERC721Received(address _from, uint _tokenId, bytes _extraData) external returns(bytes4) {
        _deposit(_from, msg.sender, _tokenId, _extraData);
        return ERC721_RECEIVED_OLD;
    }

    // @dev expected callback (include operator)
    function onERC721Received(address _operator, address _from, uint _tokenId, bytes _extraData) external returns(bytes4) {
        _deposit(_from, msg.sender, _tokenId, _extraData);
        return ERC721_RECEIVED;
    }

    // @dev Extend item listing: new expiry = current expiry + defaultExpiry
    // @param _contract whitelisted contract
    // @param _tokenId  tokenId
    function extendItem(address _contract, uint _tokenId) public onlyWhitelisted(_contract) returns(bool) {
        bytes32 key = _getHashKey(_contract, _tokenId);
        address seller = listings[key].seller;

        require(seller == msg.sender, "Only seller can extend listing.");
        require(listings[key].expiry > 0, "Item not listed.");

        listings[key].expiry = now + defaultExpiry;

        emit LogListingExtended(seller, _contract, _tokenId, listings[key].createdAt, listings[key].expiry);

        return true;
    }

    // @dev Withdraw item from marketplace back to seller
    // @param _contract whitelisted contract
    // @param _tokenId  tokenId
    function withdrawItem(address _contract, uint _tokenId) public onlyWhitelisted(_contract) {
        bytes32 key = _getHashKey(_contract, _tokenId);
        address seller = listings[key].seller;

        require(seller == msg.sender, "Only seller can withdraw listing.");

        if (!allowWithdrawBeforeExpiry) {
            require(listings[key].expiry <= now, "Withdraw only available after expired.");
        }

        // Transfer item back to the seller
        ERC721 gameToken = ERC721(_contract);
        gameToken.safeTransferFrom(this, seller, _tokenId);

        emit LogItemWithdrawn(seller, _contract, _tokenId, now);

        // remove listing
        _delist(key);
    }

    // ===========================================
    // Purchase Item
    // ===========================================
    // @dev Buy item with ETH. Take ETH from buyer, transfer token, transfer payment minus fee to seller
    // @param _contract  Token contract
    // @param _tokenId   Token Id
    function buyWithETH(address _contract, uint _tokenId) public onlyWhitelisted(_contract) payable {
        bytes32 key = _getHashKey(_contract, _tokenId);
        uint price = listings[key].price;
        address seller = listings[key].seller;
        Currencies currency = listings[key].currency;

        require(currency == Currencies.ETH, "Listing not in ETH.");
        require(msg.value > 0 && msg.value == price, "Invalid price.");
        require(listings[key].expiry > now, "Item expired.");

        ERC721 gameToken = ERC721(_contract);
        require(gameToken.ownerOf(_tokenId) == address(this), "Item is not available.");

        uint fee;
        (,fee) = getFee(price, msg.sender, seller, _contract); // getFee returns percentFee and fee, we only need fee

        // Transfer item token to buyer
        gameToken.safeTransferFrom(this, msg.sender, _tokenId);
        // Transfer Balance - fee to Seller
        require(seller.send(price - fee) == true, "Transfer to seller failed.");

        // delist item
        _delist(key);

        // Emit event
        emit LogItemSold(msg.sender, seller, _contract, _tokenId, price, currency, now);
    }

    // Buy with PLAT requires calling BitGuildToken contract, this is the callback
    // call to approve already verified the token ownership, no checks required
    // @param _buyer     buyer
    // @param _value     PLAT amount (big number)
    // @param _PLAT      BitGuild token address
    // @param _extraData address _gameContract, uint _tokenId
    function receiveApproval(address _buyer, uint _value, BitGuildToken _PLAT, bytes _extraData) public {
        require(_extraData.length > 0, "No extraData provided.");
        require(msg.sender == address(PLAT), "Unauthorized PLAT contract address.");

        address token;
        uint tokenId;
        (token, tokenId) = _decodeBuyData(_extraData);
        bytes32 key = _getHashKey(token, tokenId);
        address seller = listings[key].seller;

        require(listings[key].currency == Currencies.PLAT, "Listing not in PLAT.");
        require(_value > 0 && _value == listings[key].price, "Invalid price.");
        require(listings[key].expiry > now, "Item expired.");

        ERC721 gameToken = ERC721(token);
        require(gameToken.ownerOf(tokenId) == address(this), "Item is not available.");

        uint fee;
        (,fee) = getFee(_value, _buyer, seller, token); // getFee returns percentFee and fee, we only need fee


        // Transfer PLAT to marketplace contract
        require(_PLAT.transferFrom(_buyer, address(this), _value), "PLAT payment transfer failed.");
        // Transfer item token to buyer
        gameToken.safeTransferFrom(this, _buyer, tokenId);
        // Transfer Balance - fee to Seller
        _PLAT.transfer(seller, _value - fee);

        // delist item
        _delist(key);

        // Emit event
        emit LogItemSold(_buyer, seller, token, tokenId, _value, listings[key].currency, now);
    }

    // ===========================================
    // Admin Functions
    // ===========================================
    // @dev Update fee provider contract
    function updateAllowWithdrawBeforeExpiry(bool _allow) public onlyOperator {
        allowWithdrawBeforeExpiry = _allow;
    }

    // @dev Update fee provider contract
    function updateFeeProvider(address _newAddr) public onlyOperator {
        require(_newAddr != address(0), "Invalid contract address.");
        FeeProvider = BitGuildFeeProvider(_newAddr);
    }

    // @dev Update whitelist contract
    function updateWhitelist(address _newAddr) public onlyOperator {
        require(_newAddr != address(0), "Invalid contract address.");
        Whitelist = BitGuildWhitelist(_newAddr);
    }

    // @dev Update expiry date
    function updateExpiry(uint _days) public onlyOperator {
        require(_days > 0, "Invalid number of days.");
        defaultExpiry = _days * 1 days;
    }

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
    // @dev clear listing for hash key
    function _delist(bytes32 _key) internal {
        // remove listing
        listings[_key].currency = Currencies(0);
        listings[_key].seller = address(0);
        listings[_key].token = address(0);
        listings[_key].tokenId = 0;
        listings[_key].price = 0;
        listings[_key].createdAt = 0;
        listings[_key].expiry = 0;
    }

    function _getHashKey(address _contract, uint _tokenId) internal pure returns(bytes32 key) {
        key = keccak256(abi.encodePacked(_contract, _tokenId));
    }

    // @dev create new listing data
    function _newListing(address _seller, address _contract, uint _tokenId, uint _price, Currencies _currency) internal {
        bytes32 key = _getHashKey(_contract, _tokenId);
        uint createdAt = now;
        uint expiry = now + defaultExpiry;
        listings[key].currency = _currency;
        listings[key].seller = _seller;
        listings[key].token = _contract;
        listings[key].tokenId = _tokenId;
        listings[key].price = _price;
        listings[key].createdAt = createdAt;
        listings[key].expiry = expiry;

        emit LogListingCreated(_seller, _contract, _tokenId, createdAt, expiry);
    }

    // @dev unpack _extraData and log info
    // @param _extraData packed bytes of (uint _price, uint _currency)
    function _deposit(address _seller, address _contract, uint _tokenId, bytes _extraData) internal onlyWhitelisted(_contract) {
        uint price;
        uint currencyUint;
        (currencyUint, price) = _decodePriceData(_extraData);
        Currencies currency = Currencies(currencyUint);

        require(price > 0, "Invalid price.");

        _newListing(_seller, _contract, _tokenId, price, currency);
    }

    function _decodePriceData(bytes _extraData) internal pure returns(uint _currency, uint _price) {
        // Deserialize _extraData
        uint256 offset = 64;
        _price = _bytesToUint256(offset, _extraData);
        offset -= 32;
        _currency = _bytesToUint256(offset, _extraData);
    }

    function _decodeBuyData(bytes _extraData) internal pure returns(address _contract, uint _tokenId) {
        // Deserialize _extraData
        uint256 offset = 64;
        _tokenId = _bytesToUint256(offset, _extraData);
        offset -= 32;
        _contract = _bytesToAddress(offset, _extraData);
    }

    // @dev Decoding helper function from Seriality
    function _bytesToUint256(uint _offst, bytes memory _input) internal pure returns (uint256 _output) {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    // @dev Decoding helper functions from Seriality
    function _bytesToAddress(uint _offst, bytes memory _input) internal pure returns (address _output) {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }
}
