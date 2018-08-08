pragma solidity ^0.4.24;

import "../lib/ERC721ExtendToken.sol";
import "./AvatarChildService.sol";
import "./AvatarItemService.sol";

contract AvatarItemToken is ERC721ExtendToken, AvatarChildService {

  event TokenBurned(address owner, uint256 tokenId, uint256 _totalBurned);

  struct Item {
    address foundedBy;      // item founter
    address createdBy;       // item createdBy 
    bool isBitizenItem;    // true for avatar false for other
    int16 probability;     // < 0 , decrease the mine time, > 0 increase get rarity item  = 0 nothing ,range to -10000 ~ 10000 mean -100% ~ 100%
    uint256 node;          // node token id from node token, 0 from other
    uint256 listNumber;     // list number
    uint256 setNumber;      // set number
    //attr0 rarity         01 => Common 02 => Uncommon  03 => Rare  04 => Epic 05 => Legendary 06 => Godlike   07 => Unique
    //attr1 socket         01 => Head   02 => Top  03 => Bottom  04 => Feet  05 => Trinket  06 => Acc
    //attr2 gender         00 => Male   01 => Female    10 => Male-only   11 => Female-only
    //attr3 energy         increases extra mining times
    //attr4 ext            ext attr for future
    uint8[5] attr;
  }

  // item id index
  uint256 internal itemIndex = 0;
  // tokenId => item
  mapping(uint256 => Item) internal itemInfo;
  // burned tokenId => item
  mapping(uint256 => Item) internal burnedItems;
  
  uint256[] internal burnedTokenIds;
  // burned token id => burned ? true : false
  mapping(uint256 => bool) internal isBurnedByTokenId;

  address public avatarAccount = 0xb891C4d89C1bF012F0014F56CE523F248A07F714;

  // for development use
  function setAvatarAccount(address _account) public onlyOwner {
    avatarAccount = _account;
  }

  function getOwnedTokenIds(address _owner) external view onlyOperator returns(uint256[] _tokenIds) {
    require(_owner != address(0), "address not exist");
    return ownedTokens[_owner];
  }

  function getTokenInfo(uint256 _tokenId)
    external 
    view 
    returns(address,address,bool,int16,uint256,uint256,uint256,uint8[5]){
    require(exists(_tokenId),"token not exist");
    Item storage item = itemInfo[_tokenId];
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

  function getBurnedTokenInfo(uint256 _tokenId)
    external 
    view 
    returns(address,address,bool,int16,uint256,uint256,uint256,uint8[5]){
    require(isBurnedByTokenId[_tokenId], "Token invalid,maybe this token not burned");
    Item storage item = burnedItems[_tokenId];
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

  function isBurned(uint256 _tokenId) external view returns (bool) {
    return isBurnedByTokenId[_tokenId];
  }

  function getBurnedTokenCount() external view returns (uint256) {
    return burnedTokenIds.length;
  }

  function getBurnedTokenIdByIndex(uint256 _index) external view returns (uint256) {
    require(_index < burnedTokenIds.length, "out of bound");
    return burnedTokenIds[_index];
  }

  function burnToken(address _owner, uint256 _tokenId) external onlyOperator {
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
    onlyOperator 
    returns(uint256 _tokenId){
    _tokenId = _createToken(
      _owner,
      _mintToken(_founder, _creator, _isBitizenItem, _probability, _node,_listNumber,_setNumber, _attr));
  }
    
  function batchCreateToken(
    address _owner,
    address[] _attrs1,  // double
    bool[] _isBitizenItems, 
    int16[] _probabilitys,
    uint256[] _attrs2,
    uint8[] _attrs3  // six times
    )
    external 
    onlyOperator
    returns(uint256[] _tokenIds) {
    require(_isBitizenItems.length > 1, "Must batch create item used, not one");
    // enure the array len are valid
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
      Item memory _item = _mintToken(
        _attrs1[i * 2 + 0],  
        _attrs1[i * 2 + 1],   
        _isBitizenItems[i],  
        _probabilitys[i],  
        _attrs2[i * 3 + 0],
        _attrs2[i * 3 + 1],
        _attrs2[i * 3 + 2],
        attr
        );
      _createToken(_owner, _item);
    }
  }

  function compareItemSlots(uint256 _tokenId1, uint256 _tokenId2) external view returns (bool _res) {
    require(_tokenId1 != _tokenId2 && exists(_tokenId1) && exists(_tokenId2), "token error");
    Item storage item1 = itemInfo[_tokenId1];
    Item storage item2 = itemInfo[_tokenId2];
    _res = item1.attr[2] == item2.attr[2];
  }

  function isSameItem(uint256 _tokenId1, uint256 _tokenId2) external view returns (bool _same){
    require(_tokenId1 != _tokenId2, "tokens same");
    _same = _getItemHash(_tokenId1) == _getItemHash(_tokenId2);
  }

  function getItemHash(uint256 _tokenId) external view returns (bytes32) {
    return _getItemHash(_tokenId);
  }

  function _getItemHash(uint256 _tokenId) private view returns (bytes32) {
    require(exists(_tokenId), "token error");
    Item storage item = itemInfo[_tokenId];
    bytes memory itemBytes = abi.encodePacked(
      item.foundedBy,
      item.createdBy,
      item.isBitizenItem,
      item.probability,
      item.node,
      item.listNumber,
      item.setNumber,
      item.attr
      );
    return keccak256(itemBytes);
  }
 
  function _createToken(
    address _owner,
    Item _item
    ) private returns(uint256){
    require(_owner != address(0), "address invalid");
    uint256 tokenId = ++itemIndex;
    itemInfo[tokenId] = _item;
    _mint(_owner, tokenId); 
    return tokenId;
  }

  function _mintToken( 
    address _founder,
    address _creator, 
    bool _isBitizenItem, 
    int16 _probability,
    uint256 _node,
    uint256 _listNumber, 
    uint256 _setNumber, 
    uint8[5] _attr) private pure returns(Item _item){
    require(_probability >= -10000 && _probability <= 10000, "out of bound");
    _item = Item(_founder, _creator, _isBitizenItem, _probability, _node, _listNumber, _setNumber, _attr);
  }

  //Only the token owner have the permission to burn token
  function _burnToken(address _owner, uint256 _tokenId) private {
    require(exists(_tokenId),"Token not exist");
    require(_owner == _ownerOf(_tokenId),"Token not belong to _owner");
    burnedTokenIds.push(_tokenId);
    isBurnedByTokenId[_tokenId] = true;
    burnedItems[_tokenId] = itemInfo[_tokenId];
    delete itemInfo[_tokenId];
  
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