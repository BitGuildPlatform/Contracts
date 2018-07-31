pragma solidity ^0.4.24;

import "./ERC721ExtendToken.sol";
import "./AvatarChildService.sol";
import "./AvatarItemService.sol";

contract AvatarItemToken is ERC721ExtendToken, AvatarItemService, AvatarChildService {

  event TokenBurned(address owner, uint256 tokenId, uint256 _totalBurned);

  struct AvatarItem {
    // the listed number, the number is from the content master list
    uint32 listNumber;
    // set number, max is 99      
    uint16 setNumber;
    // true  => this itme is for avatar
    // false => this item not for avatar
    bool isBitizenItem;
    // flase => This item is not part of a set    
    // true => This item is a part of a set
    bool isSet; 
    // 00 => clothes  
    // 01 => pet 
    // type may be add in the future
    uint8 types;
    //01 => Common
    //02 => Uncommon  
    //03 => Rare      
    //04 => Epic 
    //05 => Legendary 
    //06 => Godlike   
    //07 => Unique
    uint8 rarity;  
    // 01 => Head
    // 02 => Top
    // 03 => Bottom
    // 04 => Feet           
    // 05 => Trinket      
    // 06 => Acc  
    // ...=> more 
    uint8 socket;
    // 00 => Male     
    // 01 => Female     
    // 10 => Male-only      
    // 11 => Female-only
    uint8 gender;
    // extProps for future 
    uint8 ext1;
    // extProps for future
    uint8 ext2;
  }

  AvatarItem[] avatarItems;

  mapping(uint256 => AvatarItem) burnTokens;

  uint256[] burnTokenIds;

  mapping(uint256 => bool) isBurnByTokenId;

  function getOwnedTokenIds(address _owner) external view onlyOperator returns(uint256[] _tokenIds) {
    
    return ownedTokens[_owner];
  }

  function getAvatarItemInfo(uint256 _tokenId)
    external
    view 
    returns(
    uint32 _listNumber,
    uint16 _setNumber,
    bool _isBitizenItem, 
    bool _isSet, 
    uint8[6] _attr
    ){
    (_listNumber,_setNumber,_isBitizenItem,_isSet,_attr) = _getAvatarItemInfo(_tokenId);
  }

  function getBurnedTokenInfo(uint256 _tokenId) external view returns(  
    uint32 _listNumber,
    uint16 _setNumber,
    bool _isBitizenItem, 
    bool _isSet, 
    uint8[6] _attr){
    require(isBurnByTokenId[_tokenId]);
    AvatarItem storage item = burnTokens[_tokenId];
    _listNumber = item.listNumber;
    _setNumber = item.setNumber;
    _isBitizenItem = item.isBitizenItem;
    _isSet = item.isSet;
    _attr[0] = item.types;
    _attr[1] = item.rarity;
    _attr[2] = item.socket;      
    _attr[3] = item.gender;
    _attr[4] = item.ext1;
    _attr[5] = item.ext2;  
  }

  function isBurned(uint256 _tokenId) external view returns (bool) {
    return isBurnByTokenId[_tokenId];
  }

  function getBurnTokenCount() external view returns (uint256) {
    return burnTokenIds.length;
  }

  function getBurnTokenIdByIndex(uint256 _index) external view returns (uint256) {
    require(_index < burnTokenIds.length);
    return burnTokenIds[_index];
  }

  function burnToken(address _owner, uint256 _tokenId) external onlyOperator {
    _burnToken(_owner, _tokenId);
  }
  
  function createAvatarItem( 
    address _owner, 
    uint32 _listNumber,
    uint16 _setNumber,
    bool _isBitizenItem, 
    bool _isSet, 
    uint8 _types,
    uint8 _rarity,
    uint8 _socket,
    uint8 _gender,
    uint8 _ext1,
    uint8 _ext2
    ) 
    external 
    onlyOperator 
    returns(uint256 _tokenId){
    _tokenId = _createAvatarItem(_owner, _listNumber, _setNumber, _isBitizenItem, _isSet, _types, _rarity, _socket, _gender, _ext1, _ext2);
  }

  function compareItemSlots(uint256 _tokenId1, uint256 _tokenId2) external view returns (bool _res) {
    require(_tokenId1 != _tokenId2 && exists(_tokenId1) && exists(_tokenId2));
    uint8[6] memory attrs_1;
    uint8[6] memory attrs_2;
    (,,,,attrs_1) = _getAvatarItemInfo(_tokenId1);
    (,,,,attrs_2) = _getAvatarItemInfo(_tokenId2);
    _res = attrs_1[2] == attrs_2[2];
  }

  //get the detail of the given tokenId    
  function _getAvatarItemInfo(uint256 _tokenId)
    internal
    view 
    returns(
    uint32 _listNumber,
    uint16 _setNumber,
    bool _isBitizenItem, 
    bool _isSet, 
    uint8[6] _attr
    ){
    require(exists(_tokenId), "The token is not exist");
    AvatarItem storage item = avatarItems[allTokensIndex[_tokenId]];
    _listNumber = item.listNumber;
    _isBitizenItem = item.isBitizenItem;
    _setNumber = item.setNumber;
    _isSet = item.isSet;
    _attr[0] = item.types;
    _attr[1] = item.rarity;
    _attr[2] = item.socket;      
    _attr[3] = item.gender;
    _attr[4] = item.ext1;
    _attr[5] = item.ext2;  
  }

  function _createAvatarItem (
    address _owner, 
    uint32 _listNumber,
    uint16 _setNumber,
    bool _isBitizenItem, 
    bool _isSet, 
    uint8 _types,
    uint8 _rarity,
    uint8 _socket,
    uint8 _gender,
    uint8 _ext1,
    uint8 _ext2
    )
    private 
    returns(uint256){
    require(_owner != address(0));
    AvatarItem storage avatarItem = avatarItems[avatarItems.length++];
    avatarItem.listNumber = _listNumber;
    avatarItem.setNumber = _setNumber;
    avatarItem.isBitizenItem = _isBitizenItem;
    avatarItem.isSet = _isSet;
    avatarItem.types = _types;
    avatarItem.rarity = _rarity;
    avatarItem.socket = _socket;
    avatarItem.gender = _gender;
    avatarItem.setNumber = _setNumber;
    avatarItem.ext1 = _ext1;
    avatarItem.ext2 = _ext2; 
    uint256 tokenId = avatarItems.length;
    _mint(_owner, tokenId);
    return tokenId;
  }

  //Only the token owner have the permission to burn token
  function _burnToken(address _owner, uint256 _tokenId) private {
    require(exists(_tokenId));
    require(_owner == _ownerOf(_tokenId));

    uint256 tokenIndex = allTokensIndex[_tokenId];
    burnTokens[_tokenId] = avatarItems[tokenIndex];
    burnTokenIds.push(_tokenId);
    isBurnByTokenId[_tokenId] = true;

    avatarItems[tokenIndex] = avatarItems[avatarItems.length.sub(1)];
    delete avatarItems[avatarItems.length.sub(1)];
  
    _burn(_owner, _tokenId);
    emit TokenBurned(_owner, _tokenId, burnTokenIds.length);
  }

  function () public payable {
    revert();
  }

}