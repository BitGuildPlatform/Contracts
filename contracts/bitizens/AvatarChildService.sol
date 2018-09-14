pragma solidity ^0.4.24;
/**
  if a ERC721 item want to mount to avatar, it must to inherit this.
 */
interface AvatarChildService {
  /**
      @dev if you want your contract become a avatar child, please let your contract inherit this interface
      @param _tokenId1  first child token id
      @param _tokenId2  second child token id
      @return  true will unmount first token before mount ,false will directly mount child
   */
   function compareItemSlots(uint256 _tokenId1, uint256 _tokenId2) external view returns (bool _res);

  /**
   @dev if you want your contract become a avatar child, please let your contract inherit this interface
   @return return true will be to avatar child
   */
   function isAvatarChild(uint256 _tokenId) external view returns(bool);
}