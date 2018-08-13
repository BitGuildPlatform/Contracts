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
    returns(address, address, bool, int16, uint256[4] _attr1, uint8[5] _attr2) {
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

  function getMineTrack(uint256 _tokenId) external view returns (uint256[]){
    return itemService.getMineTrack(_tokenId);
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
    uint256[4] _attr1,
    uint8[5] _attr2) 
    external
    onlyOwner
    returns(uint256 _tokenId) {
    _tokenId = _mintToken(_owner, _founder, _creator, _isBitizenItem, _probability, _attr1, _attr2);
    emit CreateToken(_owner, _tokenId);
  }
  
  function batchCreateToken(
    address _owner,
    bool[] _isBitizenItems, // base length
    int16[] _probabilitys,  // one time
    address[] _attrs1,      // two times 
    uint256[] _attrs2,      // four times 
    uint8[] _attrs3         // five times
    )
    external 
    onlyOwner
    returns(uint256[] _tokenIds) {
    require(_isBitizenItems.length > 1, "Only for batch create item");
    // enure the array len are valid
    require(_isBitizenItems.length * 1 == _probabilitys.length, "");
    require(_isBitizenItems.length * 2 == _attrs1.length, "");
    require(_isBitizenItems.length * 4 == _attrs2.length, "");
    require(_isBitizenItems.length * 5 == _attrs3.length, "");
    _tokenIds = new uint256[](_isBitizenItems.length);
    for(uint8 i = 0; i < _isBitizenItems.length; i++) {
      _tokenIds[i] = _mintToken(
        _owner,
        _attrs1[i * 2 + 0],
        _attrs1[i * 2 + 1],
        _isBitizenItems[i],
        _probabilitys[i],
        _convertToAttr2(i, _attrs2), 
        _convertToAttr3(i, _attrs3)
      );
    }
    emit BatchCreateToken(_owner, _tokenIds);
  }

  function _mintToken( 
    address _owner,
    address _founder,
    address _creator,
    bool _isBitizenItem,
    int16 _probability,
    uint256[4] _attr1,
    uint8[5] _attr2) 
    private 
    returns(uint256 _tokenId) {
    _tokenId = itemService.createToken(_owner, _founder, _creator, _isBitizenItem, _probability, _attr1, _attr2);
  }

  function _convertToAttr2(uint8 _index, uint256[] _attrs2) private pure returns (uint256[4] _attr2) {
    _attr2[0] = _attrs2[_index * 4 + 0];
    _attr2[1] = _attrs2[_index * 4 + 1];
    _attr2[2] = _attrs2[_index * 4 + 2];
    _attr2[3] = _attrs2[_index * 4 + 3];
  }

  function _convertToAttr3(uint8 _index, uint8[] _attrs3) private pure returns (uint8[5] _attr3) {
    _attr3[0] = _attrs3[_index * 5 + 0]; 
    _attr3[1] = _attrs3[_index * 5 + 1];
    _attr3[2] = _attrs3[_index * 5 + 2];
    _attr3[3] = _attrs3[_index * 5 + 3];
    _attr3[4] = _attrs3[_index * 5 + 4];
  }
}