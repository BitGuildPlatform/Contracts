pragma solidity ^0.4.20;

import "./PLATPriceOracle.sol";

contract BitGuildToken {
  function transfer(address _to, uint256 _value) public;
}

contract BitGuildTopUp {
  // Token contract
  BitGuildToken public token;

  // Oracle contract
  PLATPriceOracle public oracle;

  // Address where funds are collected
  address public wallet;

  event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);

  constructor(address _token, address _oracle, address _wallet) public {
    require(_token != address(0));
    require(_oracle != address(0));
    require(_wallet != address(0));

    token = BitGuildToken(_token);
    oracle = PLATPriceOracle(_oracle);
    wallet = _wallet;
  }

  // low level token purchase function
  function buyTokens() public payable {
    // calculate token amount to be created
    uint256 tokens = getTokenAmount(msg.value, oracle.PLATprice());

    // Send tokens
    token.transfer(msg.sender, tokens);
    emit TokenPurchase(msg.sender, msg.value, tokens);

    // Send funds
    wallet.transfer(msg.value);
  }

  // Returns you how much tokens do you get for the wei passed
  function getTokenAmount(uint256 weiAmount, uint256 price) internal pure returns (uint256) {
    uint256 tokens = weiAmount / price;
    return tokens;
  }

  // fallback function
  function () external payable {
    buyTokens();
  }
}
