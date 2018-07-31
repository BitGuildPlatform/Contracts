pragma solidity ^0.4.24;
import "./BitGuildAccessAdmin.sol";

contract BitGuildAccessAdminExtend is BitGuildAccessAdmin {

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

  function doPause() external  whenNotPaused onlyOwner {
    isPaused = true;
  }

  function doUnpause() external  whenPaused onlyOwner {
    isPaused = false;
  }

  function freezeAccount(address target, bool freeze) public onlyOwner {
    frozenAccount[target] = freeze;
    emit FrozenFunds(target, freeze);
  }

}