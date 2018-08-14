pragma solidity ^0.4.24;


import "../lib/ERC998TopDownToken.sol";
import "./AvatarChildService.sol";
import "../lib/UrlStr.sol";
import "./AvatarService.sol";

contract AvatarToken is ERC998TopDownToken, AvatarService {
  
  using UrlStr for string;

  event BatchMount(address indexed from, uint256 parent, address indexed childAddr, uint256[] children);
  event BatchUnmount(address indexed from, uint256 parent, address indexed childAddr, uint256[] children);
 
  struct Avatar {
    // avatar name
    string name;
    // avatar gen,this decide the avatar appearance 
    uint256 dna;
  }

  // For erc721 metadata
  string internal BASE_URL = "https://www.bitguild.com/bitizens/api/avatar/getAvatar/00000000";

  Avatar[] avatars;

  function createAvatar(address _owner, string _name, uint256 _dna) external onlyOperator returns(uint256) {
    return _createAvatar(_owner, _name, _dna);
  }

  function getMountTokenIds(address _owner, uint256 _tokenId, address _avatarItemAddress)
  external
  view 
  onlyOperator
  existsToken(_tokenId) 
  returns(uint256[]) {
    require(tokenIdToTokenOwner[_tokenId] == _owner);
    return childTokens[_tokenId][_avatarItemAddress];
  }
  
  function updateAvatarInfo(address _owner, uint256 _tokenId, string _name, uint256 _dna) external onlyOperator existsToken(_tokenId){
    require(_owner != address(0), "Invalid address");
    require(_owner == tokenIdToTokenOwner[_tokenId] || msg.sender == owner);
    Avatar storage avatar = avatars[allTokensIndex[_tokenId]];
    avatar.name = _name;
    avatar.dna = _dna;
  }

  function updateBaseURI(string _url) external onlyOperator {
    BASE_URL = _url;
  }

  function tokenURI(uint256 _tokenId) external view existsToken(_tokenId) returns (string) {
    return BASE_URL.generateUrl(_tokenId);
  }

  function getOwnedTokenIds(address _owner) external view returns(uint256[] _tokenIds) {
    _tokenIds = ownedTokens[_owner];
  }

  function getAvatarInfo(uint256 _tokenId) external view existsToken(_tokenId) returns(string _name, uint256 _dna) {
    Avatar storage avatar = avatars[allTokensIndex[_tokenId]];
    _name = avatar.name;
    _dna = avatar.dna;
  }

  function batchMount(address _childContract, uint256[] _childTokenIds, uint256 _tokenId) external {
    uint256 _len = _childTokenIds.length;
    require(_len > 0, "No token need to mount");
    address tokenOwner = _ownerOf(_tokenId);
    require(tokenOwner == msg.sender);
    for(uint8 i = 0; i < _len; ++i) {
      uint256 childTokenId = _childTokenIds[i];
      require(ERC721(_childContract).ownerOf(childTokenId) == tokenOwner);
      _getChild(msg.sender, _tokenId, _childContract, childTokenId);
    }
    emit BatchMount(msg.sender, _tokenId, _childContract, _childTokenIds);
  }
 
  function batchUnmount(address _childContract, uint256[] _childTokenIds, uint256 _tokenId) external {
    uint256 len = _childTokenIds.length;
    require(len > 0, "No token need to unmount");
    address tokenOwner = _ownerOf(_tokenId);
    // ensure _tokenId(avatar) belong to msg.sender
    require(tokenOwner == msg.sender);
    uint256[] memory mountedTokens = childTokens[_tokenId][_childContract];
    require(mountedTokens.length > 0);
    uint256[] memory unmountTokens = new uint256[](len);
    for(uint8 i = 0; i < len; ++i) {
      uint256 childTokenId = _childTokenIds[i];
      // ensure the token is really belong to _tokenId(avatar)
      if(_isMounted(mountedTokens, childTokenId)){
        unmountTokens[i] = childTokenId;
        _transferChild(msg.sender, _childContract, childTokenId);
      } else {
        unmountTokens[i] = 0;
      }
    }
    emit BatchUnmount(msg.sender, _tokenId, _childContract, unmountTokens);
  }

  // create avatar 
  function _createAvatar(address _owner, string _name, uint256 _dna) private returns(uint256 _tokenId) {
    require(_owner != address(0));
    Avatar memory avatar = Avatar(_name, _dna);
    _tokenId = avatars.push(avatar);
    _mint(_owner, _tokenId);
  }

  function _unmountSameSocketItem(address _owner, uint256 _tokenId, address _childContract, uint256 _childTokenId) internal {
    uint256[] storage tokens = childTokens[_tokenId][_childContract];
    for(uint256 i = 0; i < tokens.length; ++i) {
      // if the child no compareItemSlots(uint256,uint256) ,this will lead to a error and stop this operate
      if(AvatarChildService(_childContract).compareItemSlots(tokens[i], _childTokenId)) {
        // unmount the old avatar item
        _transferChild(_owner, _childContract, tokens[i]);
      }
    }
  }

  // override  
  function _transfer(address _from, address _to, uint256 _tokenId) internal whenNotPaused {
    // not allown to transfer when  only one  avatar 
    require(tokenOwnerToTokenCount[_from] > 1);
    super._transfer(_from, _to, _tokenId);
  }

  // override
  function _getChild(address _from, uint256 _tokenId, address _childContract, uint256 _childTokenId) internal {
    _unmountSameSocketItem(_from, _tokenId, _childContract, _childTokenId);
    super._getChild(_from, _tokenId, _childContract, _childTokenId);
  }

  function _isMounted(uint256[] mountedTokens, uint256 _toMountToken) private pure returns (bool){
    for(uint8 i = 0; i < mountedTokens.length; i++){
      if(mountedTokens[i] == _toMountToken){
        return true;
      }
    }
    return false;
  }

  function () external payable {
    revert();
  }

}