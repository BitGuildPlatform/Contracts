pragma solidity ^0.4.24;

interface AvatarItemService {

 function getOwnedTokenIds(address _owner) external view returns(uint256[] _tokenIds);

 function getAvatarItemInfo(uint256 _tokenId)
    external
    view 
    returns(
    uint32 _listNumber,
    uint16 _setNumber,
    bool _isBitizenItem, 
    bool _isSet, 
    uint8[6] _attr
    );

  function getBurnedTokenInfo(uint256 _tokenId) external view returns(  
    uint32 _listNumber,
    uint16 _setNumber,
    bool _isBitizenItem, 
    bool _isSet, 
    uint8[6] _attr);
  
  function isBurned(uint256 _tokenId) external view returns (bool);
  function getBurnTokenCount() external view returns (uint256);
  function getBurnTokenIdByIndex(uint256 _index) external view returns (uint256);
  function burnToken(address _owner, uint256 _tokenId) external;

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
    ) external 
    returns(uint256 _tokenId);
}