pragma solidity ^0.4.24;

import "../lib/Ownable.sol";
import "./AvatarItemService.sol";
import "../lib/ERC721.sol";
contract AvatarItemOperator is Ownable {

  event BatchCreateToken(address indexed _owner, uint256[] _tokenIds);

  AvatarItemService internal itemService;

  function injectItemService(AvatarItemService _itemService) external onlyOwner {
    itemService = AvatarItemService(_itemService);
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

  function batchCreateToken(
    address _owner,
    bool[] _isBitizenItems, 
    int16[] _probabilities, 
    address[] _addresses,   
    uint256[] _attrs1,      
    uint8[] _attrs2         
    )
    external 
    onlyOwner
    returns(uint256[] _tokenIds) {
    // enure the array len are valid
    require(_isBitizenItems.length > 0, "no data provide");
    require(_isBitizenItems.length * 1 == _probabilities.length);
    require(_isBitizenItems.length * 2 == _addresses.length);
    require(_isBitizenItems.length * 4 == _attrs1.length);
    require(_isBitizenItems.length * 5 == _attrs2.length);
    _tokenIds = new uint256[](_isBitizenItems.length);
    for(uint8 i = 0; i < _isBitizenItems.length; i++) {
      _tokenIds[i] = _mintToken(
        _owner,
        _addresses[i * 2],
        _addresses[i * 2 + 1],
        _isBitizenItems[i],
        _probabilities[i],
        _convertToAttr1(i, _attrs1), 
        _convertToAttr2(i, _attrs2)
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
    internal 
    returns(uint256 _tokenId) {
    _tokenId = itemService.createToken(_owner, _founder, _creator, _isBitizenItem, _probability, _attr1, _attr2);
  }

  function _convertToAttr1(uint8 _index, uint256[] _attrs1) private pure returns (uint256[4] _attr1) {
    _attr1[0] = _attrs1[_index * 4];
    _attr1[1] = _attrs1[_index * 4 + 1];
    _attr1[2] = _attrs1[_index * 4 + 2];
    _attr1[3] = _attrs1[_index * 4 + 3];
  }

  function _convertToAttr2(uint8 _index, uint8[] _attrs2) private pure returns (uint8[5] _attr2) {
    _attr2[0] = _attrs2[_index * 5]; 
    _attr2[1] = _attrs2[_index * 5 + 1];
    _attr2[2] = _attrs2[_index * 5 + 2];
    _attr2[3] = _attrs2[_index * 5 + 3];
    _attr2[4] = _attrs2[_index * 5 + 4];
  }

  function () public {
    revert();
  }
}