pragma solidity ^0.4.24;

import "../lib/ERC721ExtendToken.sol";


contract BitizenCarToken is ERC721ExtendToken {
  
  enum CarHandleType{NULL, CREATE_CAR, UPDATE_CAR, BURN_CAR}

  event TransferStateChanged(address indexed _owner, bool _state);
  
  event CarHandleEvent(address indexed _owner, uint256 indexed _carId, CarHandleType _type);

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
  bool public carTransferState = false;

  modifier validCar(uint256 _carId) {
    require(_carId > 0 && _carId <= carIndex, "invalid car");
    _;
  }

  function changeTransferState(bool _newState) public onlyOwner {
    if(carTransferState == _newState) return;
    carTransferState = _newState;
    emit TransferStateChanged(owner, carTransferState);
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

  function createCar(address _owner, string _foundBy, uint8 _type, uint8 _ext) external onlyOperator returns(uint256) {
    require(_owner != address(0));
    BitizenCar memory car = BitizenCar(_foundBy, _type, _ext);
    uint256 carId = ++carIndex;
    carInfos[carId] = car;
    _mint(_owner, carId);
    emit CarHandleEvent(_owner, carId, CarHandleType.CREATE_CAR);
    return carId;
  }

  function updateCar(uint256 _carId, string _newFoundBy, uint8 _type, uint8 _ext) external onlyOperator {
    require(exists(_carId));
    BitizenCar storage car = carInfos[_carId];
    car.foundBy = _newFoundBy;
    car.carType = _type;
    car.ext = _ext;
    emit CarHandleEvent(_ownerOf(_carId), _carId, CarHandleType.UPDATE_CAR);
  }

  function burnCar(address _owner, uint256 _carId) external onlyOperator {
    burnedCars.push(_carId);
    isBurned[_carId] = true;
    _burn(_owner, _carId);
    emit CarHandleEvent(_owner, _carId, CarHandleType.BURN_CAR);
  }

  // override
  // add transfer condition
  function _transfer(address _from,address _to,uint256 _tokenId) internal {
    require(carTransferState == true, "not allown transfer at current time");
    super._transfer(_from, _to, _tokenId);
  }

  function () public payable {
    revert();
  }

}