pragma solidity ^0.4.24;

interface BitizenCarService {
  function isBurnedCar(uint256 _carId) external view returns (bool);
  function getOwnerCars(address _owner) external view returns(uint256[]);
  function getBurnedCarIdByIndex(uint256 _index) external view returns (uint256);
  function getCarInfo(uint256 _carId) external view returns(string, uint8, uint8);
  function createCar(address _owner, string _foundBy, uint8 _type, uint8 _ext) external returns(uint256);
  function updateCar(uint256 _carId, string _newFoundBy, uint8 _newType, uint8 _ext) external;
  function burnCar(address _owner, uint256 _carId) external;
}