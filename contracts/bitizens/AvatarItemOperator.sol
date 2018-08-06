pragma solidity ^0.4.24;

import "../lib/Ownable.sol";
import "./AvatarItemService.sol";
import "../lib/ERC721.sol";
contract AvatarItemOperator is Ownable {

  event ItemCreateSuccess(address indexed _owner, uint256 _tokenId);
  event BatchItemCreateSuccess(address indexed _owner, uint256[] _tokenIds);

  AvatarItemService internal itemService;

  function injectItemService(address _addr) external onlyOwner {
    itemService = AvatarItemService(_addr);
  }

  function createAvatarItem( 
    address _owner,
    uint32 _listNumber,
    uint8 _setNumber,
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
    onlyOwner 
    returns(uint256 _tokenId) {
    _tokenId = itemService.createAvatarItem(_owner,_listNumber,_setNumber,_isBitizenItem,_isSet,_types,_rarity,_socket,_gender,_ext1,_ext2);
    emit ItemCreateSuccess(msg.sender, _tokenId);
  }

  function getOwnedTokenIds() external view returns(uint256[] _tokenIds){
    _tokenIds = itemService.getOwnedTokenIds(msg.sender);
  }

  function getAvatarItemInfo(uint256 _tokenId)
    external
    view 
    returns(
    uint32 _listNumber,
    uint16 _setNumber,
    bool _isBitizenItem, 
    bool _isSet,
    uint8[6] _attr){
    (_listNumber,_setNumber,_isBitizenItem,_isSet,_attr) = itemService.getAvatarItemInfo(_tokenId);
  }
  
  function batchCreateItem(
    uint32[] _listNumbers,
    uint16[] _setNumbers,
    bool[] _isBitizenItems, 
    bool[] _isSets, 
    uint8[] _attrs
    )    
    external 
    onlyOwner
    returns(uint256[] _tokenIds){
    _tokenIds = itemService.batchCreateItem(msg.sender, _listNumbers, _setNumbers, _isBitizenItems, _isSets, _attrs);
    emit BatchItemCreateSuccess(msg.sender, _tokenIds);
  }
}