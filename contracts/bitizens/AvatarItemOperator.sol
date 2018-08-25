pragma solidity ^0.4.24;

import "../lib/Operator.sol";
import "./AvatarItemService.sol";
import "../lib/ERC721.sol";
contract AvatarItemOperator is Operator {

  event ItemCreated(address indexed _owner, uint256 _tokenId);
  event LimitedItemCreated(address indexed _owner, uint256 _tokenId);
  event UpdateLimitedItemCount(bytes8 _hash, uint256 _maxCount);

  // item hash => max value 
  mapping(bytes8 => uint256) internal itemLimitedCount;
  // token id => position
  mapping(uint256 => uint256) internal itemPosition;
  // item hash => index
  mapping(bytes8 => uint256) internal itemIndex;

  AvatarItemService internal itemService;
  ERC721 internal ERC721Service;

  constructor() public {
    _setDefaultLimitedItem();
  }

  function injectItemService(AvatarItemService _itemService) external onlyOwner {
    itemService = AvatarItemService(_itemService);
    ERC721Service = ERC721(_itemService);
  }

  function getOwnedTokenIds() external view returns(uint256[] _tokenIds) {
    return itemService.getOwnedTokenIds(msg.sender);
  }

  function getTokenInfo(uint256 _tokenId)
    external 
    view 
    returns(string, string, bool, uint256[4] _attr1, uint8[5] _attr2, uint16[2] _attr3) {
    return itemService.getTokenInfo(_tokenId);
  }

  function getSameItemCount(uint256 _tokenId) external view returns(uint256){
    return itemService.getSameItemCount(_tokenId);
  }

  function getSameItemTokenIdByIndex(uint256 _tokenId, uint256 _index) external view returns(uint256){
    return itemService.getSameItemTokenIdByIndex(_tokenId, _index);
  }

  function getItemHash(uint256 _tokenId) external view  returns (bytes8) {
    return itemService.getItemHash(_tokenId);
  }

  function isSameItem(uint256 _tokenId1, uint256 _tokenId2) external view returns (bool) {
    return itemService.isSameItem(_tokenId1,_tokenId2);
  }

  function getLimitedValue(uint256 _tokenId) external view returns(uint256) {
    return itemLimitedCount[itemService.getItemHash(_tokenId)];
  }
  // return the item position when get it in all same items
  function getItemPosition(uint256 _tokenId) external view returns (uint256 _pos) {
    require(ERC721Service.ownerOf(_tokenId) != address(0), "token not exist");
    _pos = itemPosition[_tokenId];
  }

  function updateLimitedItemCount(bytes8 _itemBytes8, uint256 _count) public onlyOwner {
    itemLimitedCount[_itemBytes8] = _count;
    emit UpdateLimitedItemCount(_itemBytes8, _count);
  }
  
  function createToken( 
    address _owner,
    string _founder,
    string _creator,
    bool _isBitizenItem,
    uint256[4] _attr1,
    uint8[5] _attr2,
    uint16[2] _attr3) 
    external 
    onlyOperator
    returns(uint256 _tokenId) {
    require(_attr3[0] >= 0 && _attr3[0] <= 10000, "param must be range to 0 ~ 10000 ");
    require(_attr3[1] >= 0 && _attr3[1] <= 10000, "param must be range to 0 ~ 10000 ");
    _tokenId = _mintToken(_owner, _founder, _creator, _isBitizenItem, _attr1, _attr2, _attr3);
  
  }

  // add limited item check 
  function _mintToken( 
    address _owner,
    string _founder,
    string _creator,
    bool _isBitizenItem,
    uint256[4] _attr1,
    uint8[5] _attr2,
    uint16[2] _attr3) 
    internal 
    returns(uint256) {
    uint256 tokenId = itemService.createToken(_owner, _founder, _creator, _isBitizenItem, _attr1, _attr2, _attr3);
    bytes8 itemHash = itemService.getItemHash(tokenId);
    _saveItemIndex(itemHash, tokenId);
    if(itemLimitedCount[itemHash] > 0){
      require(itemService.getSameItemCount(tokenId) <= itemLimitedCount[itemHash], "overflow");  // limited item
      emit LimitedItemCreated(_owner, tokenId);
    } else {
      emit ItemCreated(_owner, tokenId);
    }
    return tokenId;
  }

  function _saveItemIndex(bytes8 _itemHash, uint256 _tokenId) private {
    itemIndex[_itemHash]++;
    itemPosition[_tokenId] = itemIndex[_itemHash];
  }

  function _setDefaultLimitedItem() private {
    itemLimitedCount[0xc809275c18c405b7] = 3;     //  Pioneer‘s Compass
    itemLimitedCount[0x7cb371a84bb16b98] = 100;   //  Pioneer of the Wild Hat
    itemLimitedCount[0x26a27c8bf9dd554b] = 100;   //  Pioneer of the Wild Top 
    itemLimitedCount[0xa8c29099f2421c0b] = 100;   //  Pioneer of the Wild Pant
    itemLimitedCount[0x8060b7c58dce9548] = 100;   //  Pioneer of the Wild Shoes
    itemLimitedCount[0x4f7d254af1d033cf] = 25;    //  Pioneer of the Skies Hat
    itemLimitedCount[0x19b6d994c1491e27] = 25;    //  Pioneer of the Skies Top
    itemLimitedCount[0x71e84d6ef1cf6c85] = 25;    //  Pioneer of the Skies Shoes
    itemLimitedCount[0xff5f095a3a3b990f] = 25;    //  Pioneer of the Skies Pant
    itemLimitedCount[0xa066c007ef8c352c] = 1;     //  Pioneer of the Cyberspace Hat
    itemLimitedCount[0x1029368269e054d5] = 1;     //  Pioneer of the Cyberspace Top
    itemLimitedCount[0xfd0e74b52734b343] = 1;     //  Pioneer of the Cyberspace Pant
    itemLimitedCount[0xf5974771adaa3a6b] = 1;     //  Pioneer of the Cyberspace Shoes
    itemLimitedCount[0x405b16d28c964f69] = 10;    //  Pioneer of the Seas Hat
    itemLimitedCount[0x8335384d55547989] = 10;    //  Pioneer of the Seas Top
    itemLimitedCount[0x679a5e1e0312d35a] = 10;    //  Pioneer of the Seas Pant
    itemLimitedCount[0xe3d973cce112f782] = 10;    //  Pioneer of the Seas Shoes
    itemLimitedCount[0xcde6284740e5fde9] = 50;    //  DAPP T-Shirt
  }

  function () public {
    revert();
  }
}