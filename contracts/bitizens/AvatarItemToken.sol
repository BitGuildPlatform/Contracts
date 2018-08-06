pragma solidity ^0.4.24;

import "../lib/ERC721ExtendToken.sol";
import "./AvatarChildService.sol";
import "./AvatarItemService.sol";

contract AvatarItemToken is ERC721ExtendToken, AvatarItemService, AvatarChildService {

  event TokenBurned(address owner, uint256 tokenId, uint256 _totalBurned);

  struct AvatarItem {
    // the listed number, the number is from the content master list
    uint32 listNumber;
    // set number     
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

  // all token count
  uint256 internal tokenIdIndex = 0;
  // all token info
  mapping(uint256 => AvatarItem) internal tokenInfo;
  // burned token info
  mapping(uint256 => AvatarItem) internal burnedTokens;

  uint256[] internal burnTokenIds;

  mapping(uint256 => bool) internal isBurnedByTokenId;

  mapping(address => bool) internal defaultPermissionState;

  // avatar count
  address public avatarAccount = 0xb891C4d89C1bF012F0014F56CE523F248A07F714;

  // for development use
  function setAvatarAccount(address _account) public onlyOwner {
    avatarAccount = _account;
  }

  function getOwnedTokenIds(address _owner) external view onlyOperator returns(uint256[] _tokenIds) {
    require(_owner != address(0), "Owner address not exist");
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
    require(isBurnedByTokenId[_tokenId], "Token invalid,maybe this token not burned");
    AvatarItem storage item = burnedTokens[_tokenId];
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
    return isBurnedByTokenId[_tokenId];
  }

  function getBurnedTokenCount() external view returns (uint256) {
    return burnTokenIds.length;
  }

  function getBurnedTokenIdByIndex(uint256 _index) external view returns (uint256) {
    require(_index < burnTokenIds.length, "out of bound");
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

  function batchCreateItem(
    address _owner, 
    uint32[] _listNumbers,
    uint16[] _setNumbers,
    bool[] _isBitizenItems, 
    bool[] _isSets, 
    uint8[] _attrs
    )    
    external 
    onlyOperator
    returns(uint256[] _tokenIds) {
    require(_listNumbers.length > 1,"Must batch create item can be excuse, not one");
    // enure the array len are valid
    require(_listNumbers.length == _setNumbers.length,"");
    require(_listNumbers.length == _isBitizenItems.length,"");
    require(_listNumbers.length == _isSets.length,"");
    require(_listNumbers.length * 6 == _attrs.length,"");
    _tokenIds = new uint256[](_listNumbers.length);
    for(uint8 i = 0; i < _listNumbers.length; ++i) {
      uint256 tokenId = _createAvatarItem( 
        _owner,
        _listNumbers[i],
        _setNumbers[i],
        _isBitizenItems[i],
        _isSets[i],
        _attrs[i * 6 + 0],
        _attrs[i * 6 + 1],
        _attrs[i * 6 + 2],
        _attrs[i * 6 + 3],
        _attrs[i * 6 + 4],
        _attrs[i * 6 + 5]
      );
      _tokenIds[i] = tokenId;
    }
  }

  function compareItemSlots(uint256 _tokenId1, uint256 _tokenId2) external view returns (bool _res) {
    require(_tokenId1 != _tokenId2 && exists(_tokenId1) && exists(_tokenId2),"");
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
    AvatarItem storage item = tokenInfo[_tokenId];
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
    require(_owner != address(0),"Owner address not exist");
    AvatarItem memory avatarItem = AvatarItem ({
      listNumber : _listNumber,
      setNumber : _setNumber,
      isBitizenItem : _isBitizenItem,
      isSet : _isSet,
      types : _types,
      rarity : _rarity,
      socket : _socket,
      gender : _gender,
      ext1 : _ext1,
      ext2 : _ext2
    });
    tokenIdIndex++;
    tokenInfo[tokenIdIndex] = avatarItem;
    _mint(_owner, tokenIdIndex);
    return tokenIdIndex;
  }

  //Only the token owner have the permission to burn token
  function _burnToken(address _owner, uint256 _tokenId) private {
    require(exists(_tokenId),"Token not exist");
    require(_owner == _ownerOf(_tokenId),"Token not belong to _owner");

    uint256 tokenIndex = allTokensIndex[_tokenId];
    burnedTokens[_tokenId] = tokenInfo[tokenIndex];
    burnTokenIds.push(_tokenId);
    isBurnedByTokenId[_tokenId] = true;
    // set the index token is the last token
    tokenInfo[tokenIndex] = tokenInfo[tokenIdIndex.sub(1)];
    // reset the last token info as default
    delete tokenInfo[tokenIdIndex.sub(1)];
  
    _burn(_owner, _tokenId);
    emit TokenBurned(_owner, _tokenId, burnTokenIds.length);
  }

  // override 
  function _mint(address _to, uint256 _tokenId) internal {
    super._mint(_to, _tokenId);
    //Add default permission to avatar, user can change this permission by call setApprovalForAll
    operatorApprovals[_to][avatarAccount] = true;
  }

  function () public payable {
    revert();
  }
}