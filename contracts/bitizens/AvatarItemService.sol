pragma solidity ^0.4.24;

interface AvatarItemService {
  function getOwnedTokenIds(address _owner) external view returns(uint256[] _tokenIds);
  
  function getTokenInfo(uint256 _tokenId)
    external 
    view 
    returns(address,address,bool,int16,uint256,uint256,uint256,uint8[5]);

  function isBurned(uint256 _tokenId) external view returns (bool);
  function getBurnedTokenCount() external view returns (uint256);
  function getBurnedTokenIdByIndex(uint256 _index) external view returns (uint256);
  function getSameItemTokenIds(uint256 _tokenId) external view returns(uint256[]);
  function getItemHash(uint256 _tokenId) external view returns (bytes32);
  function isSameItem(uint256 _tokenId1, uint256 _tokenId2) external view returns (bool _isSame);

  function burnToken(address _owner, uint256 _tokenId) external;
  function createToken( 
    address _owner,
    address _founder,
    address _creator, 
    bool _isBitizenItem, 
    int16 _probability,
    uint256 _node,
    uint256 _listNumber, 
    uint256 _setNumber, 
    uint8[5] _attr) 
    external 
    returns(uint256 _tokenId);
}