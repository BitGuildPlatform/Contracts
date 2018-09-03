pragma solidity ^0.4.24;

import "../lib/Ownable.sol";
import "./AvatarService.sol";
import "../lib/ERC721.sol";
contract AvatarOperator is Ownable {

  // every user can own avatar count
  uint8 public PER_USER_MAX_AVATAR_COUNT = 1;

  event AvatarCreate(address indexed _owner, uint256 tokenId);

  AvatarService internal avatarService;
  address internal avatarAddress;

  modifier nameValid(string _name){
    bytes memory nameBytes = bytes(_name);
    require(nameBytes.length > 0);
    require(nameBytes.length < 16);
    for(uint8 i = 0; i < nameBytes.length; ++i) {
      uint8 asc = uint8(nameBytes[i]);
      require (
        asc == 95 || (asc >= 48 && asc <= 57) || (asc >= 65 && asc <= 90) || (asc >= 97 && asc <= 122), "Invalid name"); 
    }
    _;
  }

  function setMaxAvatarNumber(uint8 _maxNumber) external onlyOwner {
    PER_USER_MAX_AVATAR_COUNT = _maxNumber;
  }

  function injectAvatarService(address _addr) external onlyOwner {
    avatarService = AvatarService(_addr);
    avatarAddress = _addr;
  }
  
  function updateAvatarInfo(uint256 _tokenId, string _name, uint256 _dna) external nameValid(_name){
    avatarService.updateAvatarInfo(msg.sender, _tokenId, _name, _dna);
  }

  function createAvatar(string _name, uint256 _dna) external nameValid(_name) returns (uint256 _tokenId){
    require(ERC721(avatarAddress).balanceOf(msg.sender) < PER_USER_MAX_AVATAR_COUNT, "overflow");
    _tokenId = avatarService.createAvatar(msg.sender, _name, _dna);
    emit AvatarCreate(msg.sender, _tokenId);
  }

  function getMountedChildren(uint256 _tokenId, address _avatarItemAddress) external view returns(uint256[]){
    return avatarService.getMountedChildren(msg.sender, _tokenId, _avatarItemAddress);
  }

  function getAvatarInfo(uint256 _tokenId) external view returns (string _name, uint256 _dna) {
    return avatarService.getAvatarInfo(_tokenId);
  }

  function getOwnedAvatars() external view returns(uint256[] _tokenIds) {
    return avatarService.getOwnedAvatars(msg.sender);
  }

  function handleChildren(
    address _childContract, 
    uint256[] _unmountChildren, // array of unmount child ids
    uint256[] _mountChildren,   // array of mount child ids
    uint256 _avatarId)           // above ids from which avatar 
    external {
    require(_childContract != address(0),"child address error");
    avatarService.unmount(msg.sender, _childContract, _unmountChildren, _avatarId);
    avatarService.mount(msg.sender, _childContract, _mountChildren, _avatarId);
  }
}