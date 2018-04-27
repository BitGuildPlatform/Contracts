pragma solidity ^0.4.2;

contract BitGuildWhitelist {
  mapping (address => bool) public whitelist;
}

contract BitGuildToken {
  function transfer(address _to, uint256 _value) public;
}

contract PLATPriceOracle {
  uint256 public PLATprice;
}

contract Ownable {
  address public owner;

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}

contract BitGuildTopUp is Ownable {
  // Token being sold
  BitGuildToken public token;

  // Whitelist being used
  BitGuildWhitelist public whitelist;

  // Whitelist being used
  PLATPriceOracle public oracle;

  // Address where funds are collected
  address public wallet;

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);

  constructor(address _token, address _whitelist, address _oracle, address _wallet) public {
    require(_token != address(0));
    require(_whitelist != address(0));
    require(_oracle != address(0));
    require(_wallet != address(0));

    token = BitGuildToken(_token);
    whitelist = BitGuildWhitelist(_whitelist);
    oracle = PLATPriceOracle(_oracle);
    wallet = _wallet;
  }

  // low level token purchase function
  function buyTokens() public payable {
    require(whitelist.whitelist(msg.sender));

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
    revert();
  }
}
