pragma solidity ^0.4.24;

import "../lib/ERC998TopDownToken.sol";
import "../bitizens/AvatarChildService.sol";
import "../bitizens/AvatarService.sol";

contract AvatarToken is ERC998TopDownToken, AvatarService {
  
  using UrlStr for string;

  enum ChildHandleType{NULL, MOUNT, UNMOUNT}

  event ChildHandle(address indexed from, uint256 parent, address indexed childAddr, uint256[] children, ChildHandleType _type);

  event AvatarTransferStateChanged(address indexed _owner, bool _newState);

  struct Avatar {
    // avatar name
    string name;
    // avatar gen,this decide avatar appearance 
    uint256 dna;
  }
  
  // avatar id index
  uint256 internal avatarIndex = 0;
  // avatar id => avatar
  mapping(uint256 => Avatar) avatars;
  // true avatar can do transfer 
  bool public avatarTransferState = false;

  function changeAvatarTransferState(bool _newState) public onlyOwner {
    if(avatarTransferState == _newState) return;
    avatarTransferState = _newState;
    emit AvatarTransferStateChanged(owner, avatarTransferState);
  }

  function createAvatar(address _owner, string _name, uint256 _dna) external onlyOperator returns(uint256) {
    return _createAvatar(_owner, _name, _dna);
  }

  function getMountedChildren(address _owner, uint256 _avatarId, address _childAddress)
  external
  view 
  onlyOperator
  existsToken(_avatarId) 
  returns(uint256[]) {
    require(_childAddress != address(0));
    require(tokenIdToTokenOwner[_avatarId] == _owner);
    return childTokens[_avatarId][_childAddress];
  }
  
  function updateAvatarInfo(address _owner, uint256 _avatarId, string _name, uint256 _dna) external onlyOperator existsToken(_avatarId){
    require(_owner != address(0), "Invalid address");
    require(_owner == tokenIdToTokenOwner[_avatarId] || msg.sender == owner);
    Avatar storage avatar = avatars[_avatarId];
    avatar.name = _name;
    avatar.dna = _dna;
  }

  function getOwnedAvatars(address _owner) external view onlyOperator returns(uint256[] _avatars) {
    require(_owner != address(0));
    _avatars = ownedTokens[_owner];
  }

  function getAvatarInfo(uint256 _avatarId) external view existsToken(_avatarId) returns(string _name, uint256 _dna) {
    Avatar storage avatar = avatars[_avatarId];
    _name = avatar.name;
    _dna = avatar.dna;
  }

  function unmount(address _owner, address _childContract, uint256[] _children, uint256 _avatarId) external onlyOperator {
    if(_children.length == 0) return;
    require(ownerOf(_avatarId) == _owner); // check avatar owner
    uint256[] memory mountedChildren = childTokens[_avatarId][_childContract]; 
    if (mountedChildren.length == 0) return;
    uint256[] memory unmountChildren = new uint256[](_children.length); // record unmount children 
    for(uint8 i = 0; i < _children.length; i++) {
      uint256 child = _children[i];
      if(_isMounted(mountedChildren, child)){  
        unmountChildren[i] = child;
        _removeChild(_avatarId, _childContract, child);
        ERC721(_childContract).transferFrom(this, _owner, child);
      }
    }
    if(unmountChildren.length > 0 ) 
      emit ChildHandle(_owner, _avatarId, _childContract, unmountChildren, ChildHandleType.UNMOUNT);
  }

  function mount(address _owner, address _childContract, uint256[] _children, uint256 _avatarId) external onlyOperator {
    if(_children.length == 0) return;
    require(ownerOf(_avatarId) == _owner); // check avatar owner
    for(uint8 i = 0; i < _children.length; i++) {
      uint256 child = _children[i];
      require(ERC721(_childContract).ownerOf(child) == _owner); // check child owner  
      _receiveChild(_owner, _avatarId, _childContract, child);
      ERC721(_childContract).transferFrom(_owner, this, child);
    }
    emit ChildHandle(_owner, _avatarId, _childContract, _children, ChildHandleType.MOUNT);
  }

  // check every have mounted children with the will mount child relationship
  function _checkChildRule(address _owner, uint256 _avatarId, address _childContract, uint256 _child) internal {
    uint256[] memory tokens = childTokens[_avatarId][_childContract];
    if (tokens.length == 0) {
      if (!AvatarChildService(_childContract).isAvatarChild(_child)) {
        revert("it can't be avatar child");
      }
    }
    for (uint256 i = 0; i < tokens.length; i++) {
      if (AvatarChildService(_childContract).compareItemSlots(tokens[i], _child)) {
        _removeChild(_avatarId, _childContract, tokens[i]);
        ERC721(_childContract).transferFrom(this, _owner, tokens[i]);
      }
    }
  }
  /// false will ignore not mounted children on this avatar and not exist children
  function _isMounted(uint256[] mountedChildren, uint256 _toMountToken) private pure returns (bool) {
    for(uint8 i = 0; i < mountedChildren.length; i++) {
      if(mountedChildren[i] == _toMountToken){
        return true;
      }
    }
    return false;
  }

  // create avatar 
  function _createAvatar(address _owner, string _name, uint256 _dna) private returns(uint256 _avatarId) {
    require(_owner != address(0));
    Avatar memory avatar = Avatar(_name, _dna);
    _avatarId = ++avatarIndex;
    avatars[_avatarId] = avatar;
    _mint(_owner, _avatarId);
  }

  // override  
  function _transferFrom(address _from, address _to, uint256 _avatarId) internal whenNotPaused {
    // add transfer control
    require(avatarTransferState == true, "current time not allown transfer avatar");
    super._transferFrom(_from, _to, _avatarId);
  }

  // override
  function _receiveChild(address _from, uint256 _avatarId, address _childContract, uint256 _childTokenId) internal whenNotPaused {
    _checkChildRule(_from, _avatarId, _childContract, _childTokenId);
    super._receiveChild(_from, _avatarId, _childContract, _childTokenId);
  }

  function () public payable {
    revert();
  }
}