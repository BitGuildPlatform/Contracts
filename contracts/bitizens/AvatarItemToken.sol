pragma solidity ^0.4.24;

import "../lib/ERC721ExtendToken.sol";
import "./AvatarChildService.sol";
import "./AvatarItemService.sol";

contract AvatarItemToken is ERC721ExtendToken, AvatarItemService, AvatarChildService {

  struct Item {
    address foundedBy;    // item founder
    address createdBy;    // item creator
    bool isBitizenItem;   // true for avatar false for other
    int16 probability;    // < 0 , decrease the mine time, > 0 increase get rare item, range to -10000 ~ 10000 mean -100.00% ~ 100.00%
    uint256 node;         // node token id 
    uint256 listNumber;   // list number
    uint256 setNumber;    // set number
    uint256 quality;      // quality of item 
    uint8 rarity;         // 01 => Common 02 => Uncommon  03 => Rare  04 => Epic 05 => Legendary 06 => Godlike 10 => Limited
    uint8 socket;         // 01 => Head   02 => Top  03 => Bottom  04 => Feet  05 => Trinket  06 => Acc  07 => Props
    uint8 gender;         // 00 => Male   01 => Female 10 => Male-only 11 => Female-only  Unisex => 99
    uint8 energy;         // increases extra mining times
    uint8 ext;            // extra attribute for future
  }

  // item id index
  uint256 internal tokenIndex = 0;
  // tokenId => item
  mapping(uint256 => Item) internal tokenInfo;
  // all the burned token ids
  uint256[] internal burnedTokenIds;
  // check token id => isBurned
  mapping(uint256 => bool) internal isBurnedToken;
  //hash(item) => tokenIds
  mapping(bytes32 => uint256[]) internal sameItemTokenIds;
  // item token id => transfer count
  mapping(uint256 => uint256) itemTransferCount;
  // mounted item token id => item rarity
  mapping(uint256 => uint256[]) internal mineTrack;
  
  // avatar address, add default permission to handle item
  address public avatarAccount = 0xb891C4d89C1bF012F0014F56CE523F248A07F714;

  // contain burned token and exist token 
  modifier validToken(uint256 _tokenId) {
    require(_tokenId > 0 && _tokenId <= tokenIndex, "token not vaild");
    _;
  }

  modifier existToken(uint256 _tokenId){
    require(exists(_tokenId), "token error");
    _;
  }

  function setDefaultApprovalAccount(address _account) public onlyOwner {
    avatarAccount = _account;
  }

  function compareItemSlots(uint256 _tokenId1, uint256 _tokenId2)
    external
    view 
    existToken(_tokenId1)
    existToken(_tokenId2)
    returns (bool _res) {
    require(_tokenId1 != _tokenId2, "compared token shouldn't be the same");
    Item storage item1 = tokenInfo[_tokenId1];
    Item storage item2 = tokenInfo[_tokenId2];
    _res = item1.socket == item2.socket;
  }

  function getTransferCount(uint256 _tokenId) external view validToken(_tokenId) returns(uint256) {
    return itemTransferCount[_tokenId];
  }

  function getMineTrack(uint256 _tokenId) external view validToken(_tokenId) returns (uint256[]) {
    return mineTrack[_tokenId];
  }

  function getOwnedTokenIds(address _owner) external view onlyOperator returns(uint256[] _tokenIds) {
    require(_owner != address(0), "address invalid");
    return ownedTokens[_owner];
  }

  function getTokenInfo(uint256 _tokenId)
    external 
    view 
    validToken(_tokenId)
    returns(address, address, bool, int16, uint256[4] _attr1, uint8[5] _attr2) {
    Item storage item = tokenInfo[_tokenId];
    _attr1[0] = item.node;
    _attr1[1] = item.listNumber;
    _attr1[2] = item.setNumber;
    _attr1[3] = item.quality;  
    _attr2[0] = item.rarity;
    _attr2[1] = item.socket;
    _attr2[2] = item.gender;
    _attr2[3] = item.energy;
    _attr2[4] = item.ext;
    return (
      item.foundedBy,
      item.createdBy,
      item.isBitizenItem,
      item.probability,
      _attr1,
      _attr2
      );
  }

  function isBurned(uint256 _tokenId) external view validToken(_tokenId) returns (bool) {
    return isBurnedToken[_tokenId];
  }

  function getBurnedTokenCount() external view returns (uint256) {
    return burnedTokenIds.length;
  }

  function getBurnedTokenIdByIndex(uint256 _index) external view returns (uint256) {
    require(_index < burnedTokenIds.length, "out of boundary");
    return burnedTokenIds[_index];
  }
  
  function getSameItemTokenIds(uint256 _tokenId) external view validToken(_tokenId) returns(uint256[]) {
    return sameItemTokenIds[_getItemHash(_tokenId)];
  }

  function getItemHash(uint256 _tokenId) external view validToken(_tokenId) returns (bytes32) {
    return _getItemHash(_tokenId);
  }

  function isSameItem(uint256 _tokenId1, uint256 _tokenId2)
  external
  view
  validToken(_tokenId1)
  validToken(_tokenId2)
  returns (bool _isSame)
  {
    if(_tokenId1 == _tokenId2) {
      _isSame = true;
    } else {
      _isSame = _getItemHash(_tokenId1) == _getItemHash(_tokenId2);
    }
  }

  function addMineTrack(uint256 _tokenId, uint8 _rarity) external onlyOperator {
    require(exists(_tokenId), "token error");
    mineTrack[_tokenId].push(_rarity);
  }

  function burnToken(address _owner, uint256 _tokenId) external onlyOperator existToken(_tokenId) {
    _burnToken(_owner, _tokenId);
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
    onlyOperator
    returns(uint256 _tokenId) {
    require(_owner != address(0), "address invalid");
    Item memory item = _mintToken(_founder, _creator, _isBitizenItem, _probability, _attr1, _attr2);
    _tokenId = ++tokenIndex;
    tokenInfo[_tokenId] = item;
    _mint(_owner, _tokenId);
    sameItemTokenIds[_getItemHash(_tokenId)].push(_tokenId);
  }

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
  external 
  onlyOperator
  existToken(_tokenId) 
  {
    Item storage item = tokenInfo[_tokenId];
    if (item.isBitizenItem != _isBitizenItem)
      item.isBitizenItem = _isBitizenItem;
    if (item.probability != _probability)
      item.probability = _probability;
    if (item.node != _node)
      item.node = _node;
    if (item.listNumber != _listNumber)
      item.listNumber = _listNumber;
    if (item.setNumber != _setNumber)
      item.setNumber = _setNumber;
    if (item.quality != _quality)
      item.quality = _quality;
    if (item.rarity != _rarity)
      item.rarity = _rarity;
    if (item.socket != _socket)
      item.socket = _socket;
    if (item.gender != _gender)
      item.gender = _gender;  
    if (item.energy != _energy)
      item.energy = _energy; 
    if (item.ext != _ext)
      item.ext = _ext; 
  }
    
  function _getItemHash(uint256 _tokenId) private view returns (bytes32) {
    Item storage item = tokenInfo[_tokenId];
    bytes memory itemBytes = abi.encodePacked(
      item.isBitizenItem,
      item.probability,
      item.node,
      item.listNumber,
      item.setNumber,
      item.quality,
      item.rarity,
      item.socket,
      item.gender,
      item.energy,
      item.ext
      );
    return keccak256(itemBytes);
  }

  function _mintToken( 
    address _founder,
    address _creator, 
    bool _isBitizenItem, 
    int16 _probability,
    uint256[4] _attr1, 
    uint8[5] _attr2) 
    private
    pure
    returns(Item _item) {
    require(_probability >= -10000 && _probability <= 10000, "out of range");
    _item = Item(
      _founder, 
      _creator, 
      _isBitizenItem, 
      _probability, 
      _attr1[0],
      _attr1[1], 
      _attr1[2], 
      _attr1[3],
      _attr2[0], 
      _attr2[1], 
      _attr2[2], 
      _attr2[3],
      _attr2[4]
    );
  }

  //Only the token owner have the permission to burn token
  function _burnToken(address _owner, uint256 _tokenId) private {
    require(_owner == _ownerOf(_tokenId), "no permission");
    burnedTokenIds.push(_tokenId);
    isBurnedToken[_tokenId] = true;
    _burn(_owner, _tokenId);
  }

  // override 
  //Add default permission to avatar, user can change this permission by call setApprovalForAll
  function _mint(address _to, uint256 _tokenId) internal {
    super._mint(_to, _tokenId);
    operatorApprovals[_to][avatarAccount] = true;
  }

  // override
  // record every token transfer count
  function _transfer(address _from, address _to, uint256 _tokenId) internal {
    super._transfer(_from, _to, _tokenId);
    itemTransferCount[_tokenId]++;
  }

  function () public payable {
    revert("your eth get lost");
  }
}