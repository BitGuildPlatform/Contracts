pragma solidity ^0.4.24;

import "../shared/BitGuildAccessAdmin.sol";
import "./AvatarItemService.sol";
import "../lib/ERC721.sol";
contract AvatarItemOperator is BitGuildAccessAdmin {

  event AvatarItemCreateSuccess(address indexed _owner, uint256 _tokenId);

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
    ) external onlyOperator returns(uint256 _tokenId)  {
    _tokenId = itemService.createAvatarItem(_owner,_listNumber,_setNumber,_isBitizenItem,_isSet,_types,_rarity,_socket,_gender,_ext1,_ext2);
    emit AvatarItemCreateSuccess(msg.sender, _tokenId);
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
}