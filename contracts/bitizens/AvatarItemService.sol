pragma solidity ^0.4.24;

interface AvatarItemService {

  function getTransferCount(uint256 _tokenId) external view returns(uint256);
  function getOwnedTokenIds(address _owner) external view returns(uint256[] _tokenIds);
  
  function getTokenInfo(uint256 _tokenId)
    external 
    view 
    returns(address, address, bool, int16, uint256[4] _attr1, uint8[5] _attr2);

  function isBurned(uint256 _tokenId) external view returns (bool); 
  function getBurnedTokenCount() external view returns (uint256);
  function getBurnedTokenIdByIndex(uint256 _index) external view returns (uint256);
  function getSameItemTokenIds(uint256 _tokenId) external view returns(uint256[]);
  function getItemHash(uint256 _tokenId) external view returns (bytes32);
  function isSameItem(uint256 _tokenId1, uint256 _tokenId2) external view returns (bool _isSame);
  function addMineTrack(uint256 _tokenId, uint8 _rarity) external;
  function getMineTrack(uint256 _tokenId) external view returns (uint256[]);
  
  function burnToken(address _owner, uint256 _tokenId) external;
  /**
    @param _owner         owner of the token
    @param _founder       founder of the token
    @param _creator       creator of the token
    @param _isBitizenItem true is for bitizen or false
    @param _probability   probability of the item 
    @param _attr1         _atrr1[0] => node   _atrr1[1] => listNumber _atrr1[2] => setNumber  _atrr1[3] => quality
    @param _attr2         _atrr2[0] => rarity _atrr2[1] => socket     _atrr2[2] => gender     _atrr2[3] => energy  _atrr2[4] => ext 
    @return               the token id
   */
  function createToken( 
    address _owner,
    address _founder,
    address _creator, 
    bool _isBitizenItem, 
    int16 _probability,
    uint256[4] _attr1,
    uint8[5] _attr2) 
    external  
    returns(uint256 _tokenId);

  function updateToken(
    uint256 _tokenId,
    bool  _isBitizenItem,
    int16 _probability,
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
  external;
}