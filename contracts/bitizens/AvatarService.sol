pragma solidity ^0.4.24;

interface AvatarService {
  function updateAvatarInfo(address _owner, uint256 _tokenId, string _name, uint256 _dna) external;
  function createAvatar(address _owner, string _name, uint256 _dna) external  returns(uint256);
  function getMountedChildren(address _owner,uint256 _tokenId, address _childAddress) external view returns(uint256[]); 
  function getAvatarInfo(uint256 _tokenId) external view returns (string _name, uint256 _dna);
  function getOwnedAvatars(address _owner) external view returns(uint256[] _avatars);
  function unmount(address _owner, address _childContract, uint256[] _children, uint256 _avatarId) external;
  function mount(address _owner, address _childContract, uint256[] _children, uint256 _avatarId) external;
}