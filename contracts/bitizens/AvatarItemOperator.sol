pragma solidity ^0.4.24;

import "../lib/Ownable.sol";
import "./AvatarItemService.sol";
import "../lib/ERC721.sol";
contract AvatarItemOperator is Ownable {

  event CreateToken(address indexed _owner, uint256 indexed _tokenId);
  event BatchCreateToken(address indexed _owner, uint256[] _tokenIds);
  event BurnToken(address indexed _owner, uint256 indexed _tokenId);

  AvatarItemService internal itemService;

  function injectItemService(address _addr) external onlyOwner {
    itemService = AvatarItemService(_addr);
  }

  function getOwnedTokenIds() external view returns(uint256[] _tokenIds) {
    return itemService.getOwnedTokenIds(msg.sender);
  }

  function getTokenInfo(uint256 _tokenId)
    external 
    view 
    returns(address,address,bool,int16,uint256,uint256,uint256,uint8[5]) {
    return itemService.getTokenInfo(_tokenId);
  }

  function isBurned(uint256 _tokenId) external view returns (bool) {
    return itemService.isBurned(_tokenId);
  }

  function getBurnedTokenCount() external view returns (uint256) {
    return itemService.getBurnedTokenCount();
  }
  
  function getBurnedTokenIdByIndex(uint256 _index) external view returns (uint256) {
    return itemService.getBurnedTokenIdByIndex(_index);
  }

  function getSameItemTokenIds(uint256 _tokenId) external view returns(uint256[]) {
    return itemService.getSameItemTokenIds(_tokenId);
  }

  function isSameItem(uint256 _tokenId1, uint256 _tokenId2) external view returns (bool) {
    return itemService.isSameItem(_tokenId1,_tokenId2);
  }

  function getSameItemCount(uint256 _tokenId) external view returns(uint256) {
    return itemService.getSameItemTokenIds(_tokenId).length;
  }

  function isOnlyItem(uint256 _tokenId) external view returns (bool) {
    uint256[] memory tokenIds = itemService.getSameItemTokenIds(_tokenId);
    return tokenIds.length == 1 && tokenIds[0] == _tokenId;
  }

  function burnToken(uint256 _tokenId) external {
    itemService.burnToken(msg.sender, _tokenId);
    emit BurnToken(msg.sender, _tokenId);
  }

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
    onlyOwner
    returns(uint256 _tokenId) {
    _tokenId = _mintToken(_owner, _founder, _creator, _isBitizenItem, _probability, _node, _listNumber, _setNumber, _attr);
    emit CreateToken(_owner, _tokenId);
  }

  function batchCreateToken(
    address _owner,
    address[] _attrs1,      // double
    bool[] _isBitizenItems, // base length
    int16[] _probabilitys,  // one time
    uint256[] _attrs2,      // triple
    uint8[] _attrs3         // five times
    )
    external 
    onlyOwner
    returns(uint256[] _tokenIds) {
    require(_isBitizenItems.length > 1, "Must batch create item used, not one");
    // enure the array len are valid
    require(_isBitizenItems.length * 1 == _probabilitys.length, "");
    require(_isBitizenItems.length * 2 == _attrs1.length, "");
    require(_isBitizenItems.length * 3 == _attrs2.length, "");
    require(_isBitizenItems.length * 5 == _attrs3.length, "");
    _tokenIds = new uint256[](_isBitizenItems.length);
    for(uint8 i = 0; i < _isBitizenItems.length; i++) {
      uint8[5] memory attr;
      attr[0] = _attrs3[i * 5 + 0]; 
      attr[1] = _attrs3[i * 5 + 1];
      attr[2] = _attrs3[i * 5 + 2];
      attr[3] = _attrs3[i * 5 + 3];
      attr[4] = _attrs3[i * 5 + 4];
      _tokenIds[i] = _mintToken(
        _owner,
        _attrs1[i * 2 + 0],  
        _attrs1[i * 2 + 1],   
        _isBitizenItems[i],  
        _probabilitys[i],  
        _attrs2[i * 3 + 0],
        _attrs2[i * 3 + 1],
        _attrs2[i * 3 + 2],
        attr);
    }
    emit BatchCreateToken(_owner, _tokenIds);
  }

  function _mintToken( 
    address _owner,
    address _founder,
    address _creator, 
    bool _isBitizenItem, 
    int16 _probability,
    uint256 _node,
    uint256 _listNumber, 
    uint256 _setNumber, 
    uint8[5] _attr) private returns(uint256 _tokenId) {
    _tokenId = itemService.createToken(_owner, _founder, _creator, _isBitizenItem, _probability, _node, _listNumber, _setNumber, _attr);
  }
}