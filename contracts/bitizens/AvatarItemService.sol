pragma solidity ^0.4.24;

interface AvatarItemService {

  function getTransferTimes(uint256 _tokenId) external view returns(uint256);
  function getOwnedItems(address _owner) external view returns(uint256[] _tokenIds);
  
  function getItemInfo(uint256 _tokenId)
    external 
    view 
    returns(string, string, bool, uint256[4] _attr1, uint8[5] _attr2, uint16[2] _attr3);

  function isBurned(uint256 _tokenId) external view returns (bool); 
  function isSameItem(uint256 _tokenId1, uint256 _tokenId2) external view returns (bool _isSame);
  function getBurnedItemCount() external view returns (uint256);
  function getBurnedItemByIndex(uint256 _index) external view returns (uint256);
  function getSameItemCount(uint256 _tokenId) external view returns(uint256);
  function getSameItemIdByIndex(uint256 _tokenId, uint256 _index) external view returns(uint256);
  function getItemHash(uint256 _tokenId) external view returns (bytes8); 

  function burnItem(address _owner, uint256 _tokenId) external;
  /**
    @param _owner         owner of the token
    @param _founder       founder type of the token 
    @param _creator       creator type of the token
    @param _isBitizenItem true is for bitizen or false
    @param _attr1         _atrr1[0] => node   _atrr1[1] => listNumber _atrr1[2] => setNumber  _atrr1[3] => quality
    @param _attr2         _atrr2[0] => rarity _atrr2[1] => socket     _atrr2[2] => gender     _atrr2[3] => energy  _atrr2[4] => ext 
    @param _attr3         _atrr3[0] => miningTime  _atrr3[1] => magicFind     
    @return               token id
   */
  function createItem( 
    address _owner,
    string _founder,
    string _creator, 
    bool _isBitizenItem, 
    uint256[4] _attr1,
    uint8[5] _attr2,
    uint16[2] _attr3)
    external  
    returns(uint256 _tokenId);

  function updateItem(
    uint256 _tokenId,
    bool  _isBitizenItem,
    uint16 _miningTime,
    uint16 _magicFind,
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
