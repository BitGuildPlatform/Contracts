pragma solidity ^0.4.24;

import "./AvatarItemOperator.sol";

contract AvatarItemPresale is AvatarItemOperator {

  // item hash => max value 
  mapping(bytes8 => uint256) internal itemLimitedCount;
  
  constructor() public {
    //all presale item hash should be set here
    itemLimitedCount[0x64f9474c] = 2;
  }

  function addLimitedItem(bytes8 _itemBytes8, uint256 _limitedValue) public onlyOwner {
    itemLimitedCount[_itemBytes8] = _limitedValue;
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

  function getLimitedValue(uint256 _tokenId) public view returns(uint256) {
    return itemLimitedCount[itemService.getItemHash(_tokenId)];
  }

  // override
  // add presale check 
  function _mintToken( 
    address _owner,
    address _founder,
    address _creator,
    bool _isBitizenItem,
    int16 _probability,
    uint256[4] _attr1,
    uint8[5] _attr2) 
    internal 
    returns(uint256) {
    uint256 _tokenId = itemService.createToken(_owner, _founder, _creator, _isBitizenItem, _probability, _attr1, _attr2);
    bytes8 itemHash = itemService.getItemHash(_tokenId);
    if(itemLimitedCount[itemHash] > 0){
      require(itemService.getSameItemCount(_tokenId) <= itemLimitedCount[itemHash], "overflow");
    }
  }
}