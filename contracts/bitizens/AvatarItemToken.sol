pragma solidity ^0.4.24;

import "../lib/ERC721ExtendToken.sol";
import "./AvatarItemService.sol";
import "./AvatarChildService.sol";

contract AvatarItemToken is ERC721ExtendToken, AvatarItemService, AvatarChildService {

  enum ItemHandleType{NULL, CREATE_ITEM, UPDATE_ITEM, BURN_ITEM}
  
  event ItemHandleEvent(address indexed _owner, uint256 indexed _itemId,ItemHandleType _type);

  struct AvatarItem {
    string foundedBy;     // item founder
    string createdBy;     // item creator
    bool isBitizenItem;   // true for bitizen false for other
    uint16 miningTime;    // decrease the mine time, range to 0 ~ 10000/0.00% ~ 100.00%
    uint16 magicFind;     // increase get rare item, range to 0 ~ 10000/0.00% ~ 100.00%
    uint256 node;         // node token id 
    uint256 listNumber;   // list number
    uint256 setNumber;    // set number
    uint256 quality;      // quality of item 
    uint8 rarity;         // 01 => Common 02 => Uncommon  03 => Rare  04 => Epic 05 => Legendary 06 => Godlike 10 => Limited
    uint8 socket;         // 01 => Head   02 => Top  03 => Bottom  04 => Feet  05 => Trinket  06 => Acc  07 => Props 
    uint8 gender;         // 00 => Male   01 => Female 10 => Male-only 11 => Female-only  Unisex => 99
    uint8 energy;         // increases extra mining times
    uint8 ext;            // extra attribute for future
  }
  
  // item id index
  uint256 internal itemIndex = 0;
  // tokenId => item
  mapping(uint256 => AvatarItem) internal avatarItems;
  // all the burned token ids
  uint256[] internal burnedItemIds;
  // check token id => isBurned
  mapping(uint256 => bool) internal isBurnedItem;
  // hash(item) => tokenIds
  mapping(bytes8 => uint256[]) internal sameItemIds;
  // token id => index in the same item token ids array
  mapping(uint256 => uint256) internal sameItemIdIndex;
  // token id => hash(item)
  mapping(uint256 => bytes8) internal itemIdToHash;
  // item token id => transfer count
  mapping(uint256 => uint256) internal itemTransferCount;

  // avatar address, add default permission to handle item
  address internal avatarAccount = this;

  // contain burned token and exist token 
  modifier validItem(uint256 _itemId) {
    require(_itemId > 0 && _itemId <= itemIndex, "token not vaild");
    _;
  }

  modifier itemExists(uint256 _itemId){
    require(exists(_itemId), "token error");
    _;
  }

  function setDefaultApprovalAccount(address _account) public onlyOwner {
    avatarAccount = _account;
  }

  function compareItemSlots(uint256 _itemId1, uint256 _itemId2)
    external
    view
    itemExists(_itemId1)
    itemExists(_itemId2)
    returns (bool) {
    require(_itemId1 != _itemId2, "compared token shouldn't be the same");
    return avatarItems[_itemId1].socket == avatarItems[_itemId2].socket;
  }

  function isAvatarChild(uint256 _itemId) external view returns(bool){
    return true;
  }

  function getTransferTimes(uint256 _itemId) external view validItem(_itemId) returns(uint256) {
    return itemTransferCount[_itemId];
  }

  function getOwnedItems(address _owner) external view onlyOperator returns(uint256[] _items) {
    require(_owner != address(0), "address invalid");
    return ownedTokens[_owner];
  }

  function getItemInfo(uint256 _itemId)
    external 
    view 
    validItem(_itemId)
    returns(string, string, bool, uint256[4] _attr1, uint8[5] _attr2, uint16[2] _attr3) {
    AvatarItem storage item = avatarItems[_itemId];
    _attr1[0] = item.node;
    _attr1[1] = item.listNumber;
    _attr1[2] = item.setNumber;
    _attr1[3] = item.quality;  
    _attr2[0] = item.rarity;
    _attr2[1] = item.socket;
    _attr2[2] = item.gender;
    _attr2[3] = item.energy;
    _attr2[4] = item.ext;
    _attr3[0] = item.miningTime;
    _attr3[1] = item.magicFind;
    return (item.foundedBy, item.createdBy, item.isBitizenItem, _attr1, _attr2, _attr3);
  }

  function isBurned(uint256 _itemId) external view validItem(_itemId) returns (bool) {
    return isBurnedItem[_itemId];
  }

  function getBurnedItemCount() external view returns (uint256) {
    return burnedItemIds.length;
  }

  function getBurnedItemByIndex(uint256 _index) external view returns (uint256) {
    require(_index < burnedItemIds.length, "out of boundary");
    return burnedItemIds[_index];
  }

  function getSameItemCount(uint256 _itemId) external view validItem(_itemId) returns(uint256) {
    return sameItemIds[itemIdToHash[_itemId]].length;
  }
  
  function getSameItemIdByIndex(uint256 _itemId, uint256 _index) external view validItem(_itemId) returns(uint256) {
    bytes8 itemHash = itemIdToHash[_itemId];
    uint256[] storage items = sameItemIds[itemHash];
    require(_index < items.length, "out of boundray");
    return items[_index];
  }

  function getItemHash(uint256 _itemId) external view validItem(_itemId) returns (bytes8) {
    return itemIdToHash[_itemId];
  }

  function isSameItem(uint256 _itemId1, uint256 _itemId2)
    external
    view
    validItem(_itemId1)
    validItem(_itemId2)
    returns (bool _isSame) {
    if(_itemId1 == _itemId2) {
      _isSame = true;
    } else {
      _isSame = _calcuItemHash(_itemId1) == _calcuItemHash(_itemId2);
    }
  }

  function burnItem(address _owner, uint256 _itemId) external onlyOperator itemExists(_itemId) {
    _burnItem(_owner, _itemId);
  }

  function createItem( 
    address _owner,
    string _founder,
    string _creator, 
    bool _isBitizenItem, 
    uint256[4] _attr1,
    uint8[5] _attr2,
    uint16[2] _attr3)
    external  
    onlyOperator
    returns(uint256 _itemId) {
    require(_owner != address(0), "address invalid");
    AvatarItem memory item = _mintItem(_founder, _creator, _isBitizenItem, _attr1, _attr2, _attr3);
    _itemId = ++itemIndex;
    avatarItems[_itemId] = item;
    _mint(_owner, _itemId);
    _saveItemHash(_itemId);
    emit ItemHandleEvent(_owner, _itemId, ItemHandleType.CREATE_ITEM);
  }

  function updateItem(
    uint256 _itemId,
    bool  _isBitizenItem,
    uint16 _miningTime,
    uint16 _magicFind,
    uint256 _node,
    uint256 _listNumber,
    uint256 _setNumber,
    uint256 _quality,
    uint8 _rarity,
    uint8 _socket,
    uint8 _gender,
    uint8 _energy,
    uint8 _ext
  ) 
  external 
  onlyOperator
  itemExists(_itemId){
    _deleteOldValue(_itemId); 
    _updateItem(_itemId,_isBitizenItem,_miningTime,_magicFind,_node,_listNumber,_setNumber,_quality,_rarity,_socket,_gender,_energy,_ext);
    _saveItemHash(_itemId);
  }

  function _deleteOldValue(uint256 _itemId) private {
    uint256[] storage tokenIds = sameItemIds[itemIdToHash[_itemId]];
    require(tokenIds.length > 0);
    uint256 lastTokenId = tokenIds[tokenIds.length - 1];
    tokenIds[sameItemIdIndex[_itemId]] = lastTokenId;
    sameItemIdIndex[lastTokenId] = sameItemIdIndex[_itemId];
    tokenIds.length--;
  }

  function _saveItemHash(uint256 _itemId) private {
    bytes8 itemHash = _calcuItemHash(_itemId);
    uint256 index = sameItemIds[itemHash].push(_itemId);
    sameItemIdIndex[_itemId] = index - 1;
    itemIdToHash[_itemId] = itemHash;
  }
    
  function _calcuItemHash(uint256 _itemId) private view returns (bytes8) {
    AvatarItem storage item = avatarItems[_itemId];
    bytes memory itemBytes = abi.encodePacked(
      item.isBitizenItem,
      item.miningTime,
      item.magicFind,
      item.node,
      item.listNumber,
      item.setNumber,
      item.quality,
      item.rarity,
      item.socket,
      item.gender,
      item.energy,
      item.ext
      );
    return bytes8(keccak256(itemBytes));
  }

  function _mintItem(  
    string _foundedBy,
    string _createdBy, 
    bool _isBitizenItem, 
    uint256[4] _attr1, 
    uint8[5] _attr2,
    uint16[2] _attr3) 
    private
    pure
    returns(AvatarItem _item) {
    _item = AvatarItem(
      _foundedBy,
      _createdBy,
      _isBitizenItem, 
      _attr3[0], 
      _attr3[1], 
      _attr1[0],
      _attr1[1], 
      _attr1[2], 
      _attr1[3],
      _attr2[0], 
      _attr2[1], 
      _attr2[2], 
      _attr2[3],
      _attr2[4]
    );
  }

  function _updateItem(
    uint256 _itemId,
    bool  _isBitizenItem,
    uint16 _miningTime,
    uint16 _magicFind,
    uint256 _node,
    uint256 _listNumber,
    uint256 _setNumber,
    uint256 _quality,
    uint8 _rarity,
    uint8 _socket,
    uint8 _gender,
    uint8 _energy,
    uint8 _ext
  ) private {
    AvatarItem storage item = avatarItems[_itemId];
    item.isBitizenItem = _isBitizenItem;
    item.miningTime = _miningTime;
    item.magicFind = _magicFind;
    item.node = _node;
    item.listNumber = _listNumber;
    item.setNumber = _setNumber;
    item.quality = _quality;
    item.rarity = _rarity;
    item.socket = _socket;
    item.gender = _gender;  
    item.energy = _energy; 
    item.ext = _ext; 
    emit ItemHandleEvent(_ownerOf(_itemId), _itemId, ItemHandleType.UPDATE_ITEM);
  }

  function _burnItem(address _owner, uint256 _itemId) private {
    burnedItemIds.push(_itemId);
    isBurnedItem[_itemId] = true;
    _burn(_owner, _itemId);
    emit ItemHandleEvent(_owner, _itemId, ItemHandleType.BURN_ITEM);
  }

  // override 
  //Add default permission to avatar, user can change this permission by call setApprovalForAll
  function _mint(address _to, uint256 _itemId) internal {
    super._mint(_to, _itemId);
    operatorApprovals[_to][avatarAccount] = true;
  }

  // override
  // record every token transfer count
  function _transfer(address _from, address _to, uint256 _itemId) internal {
    super._transfer(_from, _to, _itemId);
    itemTransferCount[_itemId]++;
  }

  function () public payable {
    revert();
  }
}