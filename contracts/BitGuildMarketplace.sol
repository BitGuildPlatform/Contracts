pragma solidity ^0.4.22;

import "./BitGuildToken.sol";
import "./BitGuildAccessAdmin.sol";
import "./BitGuildWhitelist.sol";
import "./BitGuildFeeOracle.sol";
import "./SafeMath.sol";


// @dev Interface for ERC-721 NFT
contract ERC721Interface {
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function approve(address _approved, uint256 _tokenId) external;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

/// @title ERC-721 Non-Fungible Token Standard
interface ERC721TokenReceiver {
	function onERC721Received(address _from, uint256 _tokenId, bytes data) external returns(bytes4);
	function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes data) external returns(bytes4);
}

/*
 * @title BitGuildMarketplace
 * @dev: Marketplace smart contract for BitGuild.com
 */
contract BitGuildMarketplace is BitGuildAccessAdmin, BitGuildWhitelist {
    using SafeMath for uint256;

    //from zepellin ERC721Receiver.sol
    //old version
    bytes4 constant ERC721_RECEIVED_OLD = 0xf0b9e5ba;
    //new version with operator
    bytes4 constant ERC721_RECEIVED = 0x150b7a02;

    // Predefined PLAT token
    // BitGuildToken public token = BitGuildToken(0x7E43581b19ab509BCF9397a2eFd1ab10233f27dE); // Main Net
    BitGuildToken public PLAT = BitGuildToken(0x0F2698b7605fE937933538387b3d6Fec9211477d); // Rinkeby

    uint public defaultExpiry = 7 days;   // default expiry 7 days
    // TODO: add function to modify this length 

    uint public currentItemId = 1; // auto-increment

    mapping(uint256 => address) public itemIdToContract;       // game contract the item belongs to
    mapping(uint256 => address) public itemIdToSeller;         // seller of the item. 0x0 if sold/delisted
    mapping(uint256 => uint256) public itemIdToTokenId;        // tokenId for this item
    mapping(uint256 => uint256) public itemIdToPLAT;           // price in PLAT for this item
    mapping(uint256 => uint256) public itemIdToETH;            // price in ETH for this item
    mapping(uint256 => uint256) public itemIdToCreatedAt;      // timestamp when item is listed

    event ItemDeposited(address _seller, uint _itemId, uint _createdAt, uint expiry);
    event ItemSold(address _buyer, address _seller, uint _itemId, uint _ETH, uint _PLAT);
    event ItemWithdrawn(address _seller, uint _itemId, uint _withdrawnAt);

    modifier isTokenOwner(address _contract, uint _tokenId) {
        ERC721Interface gameToken = ERC721Interface(_contract);
        require(
            gameToken.ownerOf(_tokenId) == msg.sender,
            "Seller does not own the token."
        );
        _;
    }

    modifier isItemSeller(uint _itemId) {
        require(
            itemIdToSeller[_itemId] == msg.sender,
            "Not item seller."
        );
        _;
    }

    modifier isPriceValid(uint _price) {
        require(
            _price > 0,
            "Invalid price."
        );
        _;
    }

    modifier doPricesMatchETH(uint _itemId) {
        require(
            itemIdToETH[_itemId] == msg.value,
            "Mismatched ETH prices."
        );
        _;
    }

    modifier doPricesMatchPLAT(uint _itemId, uint _price) {
        require(
            itemIdToPLAT[_itemId] == _price,
            "Mismatched PLAT prices."
        );
        _;
    }

    modifier isPLAT() {
        // Make sure it is sent from BitGuildToken
        require(
            msg.sender == address(PLAT),
            "Unauthorized PLAT contract address."
        );
        _;
    }

    // @dev fall back function
    function () external payable {
        revert();
    }

    // @dev return all available item ids
    function getAllItemIds() public view returns(uint[]) {
        // @dev Push is not supported for memory. storage costs more gas. Use manual counter instead
        uint[] memory tokens;
        uint counter = 0;
        for (uint i = 1; i <= currentItemId; i++) {
            // check if item is still available
            if (itemIdToSeller[i] != address(0)) {
                tokens[counter] = itemIdToTokenId[i];
                counter = counter.add(1);
            }
        }
        return tokens;
    }

    // @dev return all tokens belongs to a contract
    function getTokenIdsByContract(address _contract)
        public
        view
        onlyWhitelisted(_contract)
        returns(uint[])
    {
        // @dev Push is not supported for memory. storage costs more gas. Use manual counter instead
        uint[] memory tokens;
        uint counter = 0;
        for (uint i = 1; i <= currentItemId; i++) {
            if (itemIdToContract[i] == _contract) {
                tokens[counter] = itemIdToTokenId[i];
                counter = counter.add(1);
            }
        }
        return tokens;
    }

    // ===========================================
    // Deposit Item
    // ===========================================
    function onERC721Received(address _from, uint _tokenId, bytes _extraData) external returns(bytes4) {
        // TODO: use modifier for whitelist check
        // require(isWhitelisted[msg.sender]);  // make sure calling from whitelisted game contract
        _safeDeposit(_from, _tokenId, _extraData);
        return ERC721_RECEIVED_OLD;
    }
    function onERC721Received(address _operator, address _from, uint _tokenId, bytes _extraData) external returns(bytes4) {
        // TODO: use modifier for whitelist check
        // require(isWhitelisted[msg.sender]);  // make sure calling from whitelisted game contract
        _safeDeposit(_from, _tokenId, _extraData);
        return ERC721_RECEIVED;
    }

    // ===========================================
    // Purchase Item
    // ===========================================
    // TODO: add fee integration
    function buyWithETH(uint _itemId)
        public
        onlyWhitelisted(itemIdToContract[_itemId])
        doPricesMatchETH(_itemId)
        payable
        returns(bool success)
    {
        // Check for valid item Id
        _isValidItemId(_itemId);

        // Check if item is available
        _isItemAvailable(_itemId);
        // TODO: handle fees

        // Transfer ETH to service contract
        require(
            msg.sender.send(msg.value),
            "ETH transfer failed."
        );

        // Transfer item token to buyer
        _safeTransferToken(_itemId);

        // Update mappings
        address seller = itemIdToSeller[_itemId];
        itemIdToSeller[_itemId] = address(0);     // Mark item unavailable

        // Emit event
        emit ItemSold(msg.sender, seller, _itemId, msg.value, 0);
        return true;
    }

    // Buy with PLAT requires calling BitGuildToken contract, then redirect here
    function receiveApproval(address _sender, uint _value, bytes _extraData)
        public
        isPLAT
        doPricesMatchPLAT(_itemId, _value)
        returns(bool success)
    {
        require(
            _extraData.length != 0,
            "No extraData provided."
        );

        // TODO: handle fees

        // convert tokenId back to uint
        uint _itemId = _bytesToUint(_extraData);

        // Check for valid item Id
        _isValidItemId(_itemId);

        // Check if item is available
        _isItemAvailable(_itemId);

        // check if set has price and has correct price
        require(
            itemIdToPLAT[_itemId] == _value,
            "Invalid PLAT price."
        );

        // Transfer item token to buyer
        _safeTransferToken(_itemId);

        // Transfer PLAT to service contract
        require(
            PLAT.transferFrom(_sender, address(this), _value),
            "Approved PLAT transfer failed."
        );

        // Update mappings
        address seller = itemIdToSeller[_itemId];
        itemIdToSeller[_itemId] = address(0);     // Mark item unavailable

        // Emit event
        emit ItemSold(_sender, seller, _itemId, 0, _value);
        return true;
    }

    // ===========================================
    // Seller Functions
    // ===========================================
    function withdrawItem(uint _itemId)
        public
        isItemSeller(_itemId)
        returns(bool success)
    {
        // Transfer item back to seller
        address _contract = itemIdToContract[_itemId];
        uint _tokenId = itemIdToTokenId[_itemId];
        address _seller = itemIdToSeller[_itemId];

        ERC721Interface _ERC721contract = ERC721Interface(_contract);
        _ERC721contract.transferFrom(this, _seller, _tokenId);

        emit ItemWithdrawn(itemIdToSeller[_itemId], _itemId, now);

        // update mapping
        itemIdToSeller[_itemId] = address(0);
        return true;
    }

    // @dev Admin function: withdraw PLAT balance
    function withdrawPLAT() public onlyOwner {
        uint balance = PLAT.balanceOf(this);
        PLAT.transfer(msg.sender, balance);
    }

    // ===========================================
    // Admin Functions
    // ===========================================
    // @dev Admin function: withdraw ETH balance
    function withdrawETH() public onlyOwner payable {
        address(this).transfer(msg.value);
    }

    // ===========================================
    // Internal Functions
    // ===========================================
    // @dev transfer token from seller to this contract. all checks are done before calling this
    function _safeDeposit(address _from, uint _tokenId, bytes _extraData) private {
        uint price = _bytesToUint(_extraData);
        require(price > 0);                  // make sure price is valid

        // Update mappings
        itemIdToContract[currentItemId] = msg.sender;   // game contract
        itemIdToSeller[currentItemId] = _from;     // 
        itemIdToTokenId[currentItemId] = _tokenId;
        uint createdAt = now;
        uint expiry = createdAt + defaultExpiry;
        itemIdToCreatedAt[currentItemId] = createdAt;
        itemIdToPLAT[currentItemId] = price;
        // Emit event
        emit ItemDeposited(msg.sender, currentItemId, createdAt, expiry);

        // Update item count
        currentItemId = currentItemId.add(1);
    }

    // @dev safe transfer token to buyer. all checks are done before calling this.
    function _safeTransferToken(uint _itemId) private {
        // Transfer item token to buyer
        address _contract = itemIdToContract[_itemId];
        uint _tokenId = itemIdToTokenId[_itemId];

        ERC721Interface _ERC721contract = ERC721Interface(_contract);
        _ERC721contract.transferFrom(this, msg.sender, _tokenId);
    }

    function _isValidItemId(uint _itemId) private view {
        require(
            _itemId > 0 && _itemId <= currentItemId,
            "Invalid item id."
        );
    }

    function _isItemAvailable(uint _itemId) private view {
        // Check if item still available
        require(
            itemIdToSeller[_itemId] != address(0),
            "Item is not available."
        );

        // Check if token still in this contract
        address _contract = itemIdToContract[_itemId];
        uint _tokenId = itemIdToTokenId[_itemId];
        ERC721Interface _ERC721contract = ERC721Interface(_contract);
        require(
            _ERC721contract.ownerOf(_tokenId) == address(this),
            "Item is not on the exchange."
        );
    }

    // @dev helper function to convert bytes back to uint256
    function _bytesToUint(bytes _b) private pure returns(uint256) {
        uint256 number;
        for (uint i=0; i < _b.length; i++) {
            number = number + uint(_b[i]) * (2**(8 * (_b.length - (i+1))));
        }
        return number;
    }
}
