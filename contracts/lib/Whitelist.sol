pragma solidity ^0.4.22;

import "./Operator.sol";


/**
 * @title Whitelist
 * @dev A small smart contract to provide whitelist functionality and storage
 */
contract Whitelist is Operator {
    uint public total = 0;
    mapping (address => bool) public isWhitelisted;

    event AddressWhitelisted(address indexed addr, address operator);
    event AddressRemovedFromWhitelist(address indexed addr, address operator);

    // @dev Throws if _address is not in whitelist.
    modifier onlyWhitelisted(address _address) {
        require(
            isWhitelisted[_address],
            "Address is not on the whitelist."
        );
        _;
    }

    // Doesn't accept eth
    function () external payable {
        revert();
    }

    /**
     * @dev Allow operators to add whitelisted contracts
     * @param _newAddr New whitelisted contract address
     */
    function addToWhitelist(address _newAddr) public onlyOperator {
        require(
            _newAddr != address(0),
            "Invalid new address."
        );

        // Make sure no dups
        require(
            !isWhitelisted[_newAddr],
            "Address is already whitelisted."
        );

        isWhitelisted[_newAddr] = true;
        total++;
        emit AddressWhitelisted(_newAddr, msg.sender);
    }

    /**
     * @dev Allow operators to remove a contract from the whitelist
     * @param _addr Contract address to be removed
     */
    function removeFromWhitelist(address _addr) public onlyOperator {
        require(
            _addr != address(0),
            "Invalid address."
        );

        // Make sure the address is in whitelist
        require(
            isWhitelisted[_addr],
            "Address not in whitelist."
        );

        isWhitelisted[_addr] = false;
        if (total > 0) {
            total--;
        }
        emit AddressRemovedFromWhitelist(_addr, msg.sender);
    }

    /**
     * @dev Allow operators to update whitelist contracts in bulk
     * @param _addresses Array of addresses to be processed
     * @param _whitelisted Boolean value -- to add or remove from whitelist
     */
    function whitelistAddresses(address[] _addresses, bool _whitelisted) public onlyOperator {
        for (uint i = 0; i < _addresses.length; i++) {
            address addr = _addresses[i];
            if (isWhitelisted[addr] == _whitelisted) continue;
            if (_whitelisted) {
                addToWhitelist(addr);
            } else {
                removeFromWhitelist(addr);
            }
        }
    }
}
