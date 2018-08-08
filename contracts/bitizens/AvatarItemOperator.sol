pragma solidity ^0.4.24;

import "../lib/Ownable.sol";
import "./AvatarItemService.sol";
import "../lib/ERC721.sol";
contract AvatarItemOperator is Ownable {

  event ItemCreate(address indexed _owner, uint256 _tokenId);
  event BatchCreateItem(address indexed _owner, uint256[] _tokenIds);

  AvatarItemService internal itemService;

  function injectItemService(address _addr) external onlyOwner {
    itemService = AvatarItemService(_addr);
  }

  function getOwnedTokenIds() external view returns(uint256[] _tokenIds){
    _tokenIds = itemService.getOwnedTokenIds(msg.sender);
  }

  function getTokenInfo(uint256 _tokenId)
  external 
  view 
  returns(bool,bool,uint256,uint32,uint16,uint16,uint16,uint8[6]){
    return ( itemService.getTokenInfo(_tokenId) );
  }

  function getBurnedTokenInfo(uint256 _tokenId)
  external 
  view 
  returns(bool,bool,uint256,uint32,uint16,uint16,uint16,uint8[6]){
    return ( itemService.getTokenInfo(_tokenId) );
  } 

  function isBurned(uint256 _tokenId) external view returns (bool) {
    return itemService.isBurned(_tokenId);
  }

  function getBurnedTokenCount() external view returns (uint256){
    return itemService.getBurnedTokenCount();
  }

  function getBurnedTokenIdByIndex(uint256 _index) external view returns (uint256){
    return itemService.getBurnedTokenIdByIndex(_index);
  }

  function burnToken(uint256 _tokenId) external onlyOwner {
    itemService.burnToken(msg.sender, _tokenId);
  }

  function createToken( 
    address _owner, 
    bool _isBitizenItem, 
    bool _isSet, 
    uint256 _from,
    uint32 _listNumber,
    uint16 _setNumber,
    uint16 _cooldown,
    uint16 _magic,
    uint8[6] _attr) 
    external 
    onlyOwner
    returns(uint256 _tokenId){
    _tokenId = itemService.createToken(_owner,_isBitizenItem, _isSet, _from, _listNumber, _setNumber, _cooldown,_magic, _attr);
    emit ItemCreate(_owner, _tokenId);
  }

  function batchCreateToken(
    address _owner, 
    bool[] _attrs1, 
    uint256[] _froms,
    uint32[] _listNumbers,
    uint16[] _attrs2,
    uint8[] _attrs3
    )
    external 
    onlyOwner
    returns(uint256[] _tokenIds){
    _tokenIds = itemService.batchCreateToken(_owner,_attrs1, _froms, _listNumbers, _attrs2, _attrs3);
    emit BatchCreateItem(_owner, _tokenIds);
  }
}