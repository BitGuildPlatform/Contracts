pragma solidity ^0.4.24;
/**
  if a ERC721 item want to mount to avatar, it must implement the interface
 */
interface AvatarChildService {
  /**
      @dev if you want your contract become a avatar child, please let your contract implement the interface
      @param _tokenId1  first child token id
      @param _tokenId2  second child token id
      @return  true, unmount the first token before mounting, false, directly mount child
   */
   function compareItemSlots(uint256 _tokenId1, uint256 _tokenId2) external view returns (bool _res);
}