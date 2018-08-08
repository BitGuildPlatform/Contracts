pragma solidity ^0.4.24;

interface AvatarItemService {

  function getOwnedTokenIds(address _owner) external view returns(uint256[] _tokenIds);
  
  function getTokenInfo(uint256 _tokenId)
    external 
    view 
    returns(bool,bool,uint256,uint32,uint16,uint16,uint16,uint8[6]);

  function getBurnedTokenInfo(uint256 _tokenId)
    external 
    view 
    returns(bool,bool,uint256,uint32,uint16,uint16,uint16,uint8[6]);

  function isBurned(uint256 _tokenId) external view returns (bool);

  function getBurnedTokenCount() external view returns (uint256);

  function getBurnedTokenIdByIndex(uint256 _index) external view returns (uint256);

  function burnToken(address _owner, uint256 _tokenId) external;

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
    returns(uint256 _tokenId);

  function batchCreateToken(
    address _owner, 
    bool[] _attrs1,
    uint256[] _froms, 
    uint32[] _listNumbers,
    uint16[] _attrs2,
    uint8[] _attrs3
    )
    external 
    returns(uint256[] _tokenIds);

 
}