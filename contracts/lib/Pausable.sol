pragma solidity ^0.4.24;
import "./Operator.sol";

contract Pausable is Operator {

  event FrozenFunds(address target, bool frozen);

  bool public isPaused = false;
  
  mapping(address => bool)  frozenAccount;

  modifier whenNotPaused {
    require(!isPaused);
    _;
  }

  modifier whenPaused {
    require(isPaused);
    _;  
  }

  modifier whenNotFreeze(address _target) {
    require(_target != address(0));
    require(!frozenAccount[_target]);
    _;
  }

  function isFrozen(address _target) external view returns (bool) {
    require(_target != address(0));
    return frozenAccount[_target];
  }

  function doPause() external  whenNotPaused onlyOwner {
    isPaused = true;
  }

  function doUnpause() external  whenPaused onlyOwner {
    isPaused = false;
  }

  function freezeAccount(address _target, bool _freeze) public onlyOwner {
    require(_target != address(0));
    frozenAccount[_target] = _freeze;
    emit FrozenFunds(_target, _freeze);
  }

}