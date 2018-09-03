pragma solidity ^0.4.24;

import "../lib/Operator.sol";
import "./BitizenCarService.sol";
import "../lib/ERC721.sol";
contract BitizenCarOperator is Operator {

  event CreateCar(address indexed _owner, uint256 _carId);
  
  BitizenCarService internal carService;

  ERC721 internal ERC721Service;

  uint16 PER_USER_MAX_CAR_COUNT = 1;

  function injectCarService(BitizenCarService _service) public onlyOwner {
    carService = BitizenCarService(_service);
    ERC721Service = ERC721(_service);
  }

  function setMaxCount(uint16 _count) public onlyOwner {
    PER_USER_MAX_CAR_COUNT = _count;
  }

  function getOwnerCars() external view returns(uint256[]) {
    return carService.getOwnerCars(msg.sender);
  }

  function getCarInfo(uint256 _carId) external view returns(string, uint8, uint8){
    return carService.getCarInfo(_carId);
  }
  
  function createCar(string _foundBy) external returns(uint256) {
    require(ERC721Service.balanceOf(msg.sender) < PER_USER_MAX_CAR_COUNT,"user owned car count overflow");
    uint256 carId = carService.createCar(msg.sender, _foundBy, 1, 1);
    emit CreateCar(msg.sender, carId);
    return carId;
  }

  function createCarByOperator(address _owner, string _foundBy, uint8 _type, uint8 _ext) external onlyOperator returns (uint256) {
    uint256 carId = carService.createCar(_owner, _foundBy, _type, _ext);
    emit CreateCar(msg.sender, carId);
    return carId;
  }
}