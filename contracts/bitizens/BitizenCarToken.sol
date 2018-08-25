pragma solidity ^0.4.24;

import "../lib/ERC721ExtendToken.sol";


contract BitizenCarToken is ERC721ExtendToken {

  event TransferStateChanged(address indexed _owner, bool _state);

  struct BitizenCar{
    string foundBy; // founder name
    uint8 carType;  // car type
    uint8 ext;      // for future
  }
 
  // car id index
  uint256 internal carIndex = 0;

  // car id => car 
  mapping (uint256 => BitizenCar) carInfos;

  // all the burned car id
  uint256[] internal burnedCars;

  // check car id => isBurned
  mapping(uint256 => bool) internal isBurned;

  // add a switch to handle transfer
  bool public transferState = false;

  modifier validCar(uint256 _carId) {
    require(_carId > 0 && _carId <= carIndex, "invalid car");
    _;
  }

  function changeTransferState(bool _newState) public onlyOwner {
    require(transferState != _newState, "current state is you want to be");
    transferState = _newState;
    emit TransferStateChanged(owner, transferState);
  }

  function isBurnedCar(uint256 _carId) external view validCar(_carId) returns (bool) {
    return isBurned[_carId];
  }

  function getBurnedCarCount() external view returns (uint256) {
    return burnedCars.length;
  }

  function getBurnedCarIdByIndex(uint256 _index) external view returns (uint256) {
    require(_index < burnedCars.length, "out of boundary");
    return burnedCars[_index];
  }

  function getCarInfo(uint256 _carId) external view validCar(_carId) returns(string, uint8, uint8)  {
    BitizenCar storage car = carInfos[_carId];
    return(car.foundBy, car.carType, car.ext);
  }

  function getOwnerCars(address _owner) external view onlyOperator returns(uint256[]) {
    require(_owner != address(0));
    return ownedTokens[_owner];
  }

  function createCar(address _owner, string _newFoundBy, uint8 _type, uint8 _ext) external onlyOperator returns(uint256) {
    require(_owner != address(0));
    BitizenCar memory car = BitizenCar(_newFoundBy, _type, _ext);
    uint256 carId = ++carIndex;
    carInfos[carId] = car;
    _mint(_owner, carId);
    return carId;
  }

  function updateCar(uint256 _carId, string _newFoundBy, uint8 _type, uint8 _ext) external onlyOperator {
    require(exists(_carId));
    BitizenCar storage car = carInfos[_carId];
    car.foundBy = _newFoundBy;
    car.carType = _type;
    car.ext = _ext;
  }

  function burnCar(address _owner, uint256 _carId) external onlyOperator {
    require(_owner == _ownerOf(_carId), "no permission");
    burnedCars.push(_carId);
    isBurned[_carId] = true;
    _burn(_owner, _carId);
  }

  // override
  // add transfer condition
  function _transfer(address _from,address _to,uint256 _tokenId) internal {
    require(transferState == true, "not allown transfer at current time");
    super._transfer(_from, _to, _tokenId);
  }

}