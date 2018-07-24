pragma solidity ^0.4.24;

import "./BitGuildAccessAdmin.sol";


/**
 * @title BitGuildFeeProvider
 * @dev Fee definition, supports custom fees by seller or buyer or token combinations
 */
contract BitGuildFeeProvider is BitGuildAccessAdmin {
    uint constant FREE = 999;
    mapping(bytes32 => uint) public percentFee;  // Allow buyer or seller discounts

    event LogFeeChanged(address buyer, address seller, address token, uint newPercentFee, uint oldPercentFee, address operator);

    constructor() public {
        // @dev default % fee. Fixed is not supported. use percent * 100 to include 2 decimals
        bytes32 key = _getHash(address(0), address(0), address(0));
        percentFee[key] = 300;
    }

    // Default
    function () external payable {
        revert();
    }

    /**
     * @dev Allow operators to update the fee
     * @param _newFee New fee in percent x 100 (to support decimals)
     */
    function updateFee(address _buyer, address _seller, address _token, uint _newFee) public onlyOperator {
        require(
            _newFee > 0 && _newFee < 10000,
            "Invalid percent fee."
        );

        bytes32 key = _getHash(_buyer, _seller, _token);
        uint oldFee = percentFee[key];
        percentFee[key] = _newFee;

        emit LogFeeChanged(_buyer, _seller, _token, _newFee, oldFee, msg.sender);
    }

    /**
     * @dev Calculate the custom fee based on buyer, seller, game token or combo of these
     */
    function getFee(uint _price, address _buyer, address _seller, address _token) public view returns(uint percent, uint fee) {
        (percent, fee) = _getFee(_price, _buyer,_seller, _token);
    }

    /**
     * @dev Return the default fee
     * @param _price for calculating fee
     */
    function getFee(uint _price) public view returns(uint percent, uint fee) {
        (percent, fee) = _getFee(_price, address(0), address(0), address(0));
    }

    function _getFee(uint _price, address _buyer, address _seller, address _token) internal view returns(uint percent, uint fee) {
        require(
            _price > 0,
            "Invalid price."
        );

        bytes32 key = _getHash(_buyer, _seller, _token);
        percent = percentFee[key];

        // @dev Since default uint value is zero, need to distinguish Default vs FREE
        if (percent == 0) {
            bytes32 defaultKey = _getHash(address(0), address(0), address(0));
            percent = percentFee[defaultKey];
        } else if (percent == FREE) {
            percent = 0;
        }

        fee = _safeMul(_price, percent) / 10000; // adjust for percent and decimal. division always truncate
    }

    // get custom fee hash
    function _getHash(address _buyer, address _seller, address _token) internal pure returns(bytes32 key) {
        key = keccak256(abi.encodePacked(_buyer, _seller, _token));
    }

    // safe multiplication
    function _safeMul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        assert(c / a == b);
        return c;
    }
}
