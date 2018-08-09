pragma solidity ^0.4.24;

import "../lib/ERC721ExtendToken.sol";
import "./AvatarChildService.sol";
import "./AvatarItemService.sol";

contract AvatarItemToken is ERC721ExtendToken, AvatarChildService {

  event TokenBurned(address owner, uint256 tokenId, uint256 _totalBurned);

  struct Item {
    address foundedBy;     // item founter 
    address createdBy;     // item creator 
    bool isBitizenItem;    // true for avatar false for other
    int16 probability;     // < 0 , decrease the mine time, > 0 increase get rarity item  = 0 nothing ,range to -10000 ~ 10000 mean -100% ~ 100%
    uint256 node;          // node token id from node token, 0 from other
    uint256 listNumber;    // list number
    uint256 setNumber;     // set number
    //attr0 rarity         01 => Common 02 => Uncommon  03 => Rare  04 => Epic 05 => Legendary 06 => Godlike   07 => Unique
    //attr1 socket         01 => Head   02 => Top  03 => Bottom  04 => Feet  05 => Trinket  06 => Acc
    //attr2 gender         00 => Male   01 => Female    10 => Male-only   11 => Female-only
    //attr3 energy         increases extra mining times
    //attr4 ext            ext attr for future
    uint8[5] attr;
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
  mapping(bytes32 => uint256[]) sameItemTokenIds;

  // avatar address, add default permission to handle item
  address public avatarAccount = 0xb891C4d89C1bF012F0014F56CE523F248A07F714;

  // contain burned token and exist token 
  modifier validToken(uint256 _tokenId) {
    require(_tokenId > 0 && _tokenId <= tokenIndex, "token not exist");
    _;
  }

  function setDefaultApprovalAccount(address _account) public onlyOwner {
    avatarAccount = _account;
  }

  function compareItemSlots(uint256 _tokenId1, uint256 _tokenId2) external view returns (bool _res) {
    require(_tokenId1 != _tokenId2 && exists(_tokenId1) && exists(_tokenId2), "token error");
    Item storage item1 = tokenInfo[_tokenId1];
    Item storage item2 = tokenInfo[_tokenId2];
    _res = item1.attr[1] == item2.attr[1];
  }

  function getOwnedTokenIds(address _owner) external view onlyOperator returns(uint256[] _tokenIds) {
    require(_owner != address(0), "address not exist");
    return ownedTokens[_owner];
  }

  function getTokenInfo(uint256 _tokenId)
    external 
    view 
    validToken(_tokenId)
    returns(address,address,bool,int16,uint256,uint256,uint256,uint8[5]) {
    Item storage item = tokenInfo[_tokenId];
    return (
      item.foundedBy,
      item.createdBy,
      item.isBitizenItem,
      item.probability,
      item.node,
      item.listNumber,
      item.setNumber,
      item.attr
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
  
  function getSameItemTokenIds(uint256 _tokenId) external view returns(uint256[]) {
    return sameItemTokenIds[_getItemHash(_tokenId)];
  }

  function getItemHash(uint256 _tokenId) external view returns (bytes32) {
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

  function burnToken(address _owner, uint256 _tokenId) external {
    _burnToken(_owner, _tokenId);
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
    returns(uint256 _tokenId) {
    require(_owner != address(0), "address invalid");
    Item memory item = _mintToken(_founder, _creator, _isBitizenItem, _probability, _node,_listNumber,_setNumber, _attr);
    _tokenId = ++tokenIndex;
    tokenInfo[_tokenId] = item;
    _mint(_owner, _tokenId);
    sameItemTokenIds[_getItemHash(_tokenId)].push(_tokenId);
  }
    
  function _getItemHash(uint256 _tokenId) private view validToken(_tokenId) returns (bytes32) {
    Item storage item = tokenInfo[_tokenId];
    bytes memory itemBytes = abi.encodePacked(
      item.isBitizenItem,
      item.probability,
      item.node,
      item.listNumber,
      item.setNumber,
      item.attr
      );
    return keccak256(itemBytes);
  }

  function _mintToken( 
    address _founder,
    address _creator, 
    bool _isBitizenItem, 
    int16 _probability,
    uint256 _node,
    uint256 _listNumber, 
    uint256 _setNumber, 
    uint8[5] _attr) 
    private 
    view 
    onlyOperator
    returns(Item _item) {
    require(_probability >= -10000 && _probability <= 10000, "out of boundary");
    _item = Item(_founder, _creator, _isBitizenItem, _probability, _node, _listNumber, _setNumber, _attr);
  }

  //Only the token owner have the permission to burn token
  function _burnToken(address _owner, uint256 _tokenId) private onlyOperator {
    require(exists(_tokenId),"Token error");
    require(_owner == _ownerOf(_tokenId),"no permission");
    burnedTokenIds.push(_tokenId);
    isBurnedToken[_tokenId] = true;
    _burn(_owner, _tokenId);
    emit TokenBurned(_owner, _tokenId, burnedTokenIds.length);
  }

  // override 
  function _mint(address _to, uint256 _tokenId) internal {
    super._mint(_to, _tokenId);
    //Add default permission to avatar, user can change this permission by call setApprovalForAll
    operatorApprovals[_to][avatarAccount] = true;
  }

  function () public payable {
    revert("your eth get lost");
  }
}