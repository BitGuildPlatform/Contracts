pragma solidity ^0.4.24;

import "../lib/Operator.sol";


/**
 * @title BitGuildFeeProvider
 * @dev Fee definition, supports custom fees by seller or buyer or token combinations
 */
contract BitGuildFeeProvider is Operator {
    // @dev Since default uint value is zero, need to distinguish Default vs No Fee
    uint constant NO_FEE = 10000;

    // @dev default % fee. Fixed is not supported. use percent * 100 to include 2 decimals
    uint defaultPercentFee = 500; // default fee: 5%

    mapping(bytes32 => uint) public customFee;  // Allow buyer or seller or game discounts

    event LogFeeChanged(uint newPercentFee, uint oldPercentFee, address operator);
    event LogCustomFeeChanged(uint newPercentFee, uint oldPercentFee, address buyer, address seller, address token, address operator);

    // Default
    function () external payable {
        revert();
    }

    /**
     * @dev Allow operators to update the fee for a custom combo
     * @param _newFee New fee in percent x 100 (to support decimals)
     */
    function updateFee(uint _newFee) public onlyOperator {
        require(_newFee >= 0 && _newFee <= 10000, "Invalid percent fee.");

        uint oldPercentFee = defaultPercentFee;
        defaultPercentFee = _newFee;

        emit LogFeeChanged(_newFee, oldPercentFee, msg.sender);
    }

    /**
     * @dev Allow operators to update the fee for a custom combo
     * @param _newFee New fee in percent x 100 (to support decimals)
     *                enter zero for default, 10000 for No Fee
     */
    function updateCustomFee(uint _newFee, address _currency, address _buyer, address _seller, address _token) public onlyOperator {
        require(_newFee >= 0 && _newFee <= 10000, "Invalid percent fee.");

        bytes32 key = _getHash(_currency, _buyer, _seller, _token);
        uint oldPercentFee = customFee[key];
        customFee[key] = _newFee;

        emit LogCustomFeeChanged(_newFee, oldPercentFee, _buyer, _seller, _token, msg.sender);
    }

    /**
     * @dev Calculate the custom fee based on buyer, seller, game token or combo of these
     */
    function getFee(uint _price, address _currency, address _buyer, address _seller, address _token) public view returns(uint percent, uint fee) {
        bytes32 key = _getHash(_currency, _buyer, _seller, _token);
        uint customPercentFee = customFee[key];
        (percent, fee) = _getFee(_price, customPercentFee);
    }

    function _getFee(uint _price, uint _percentFee) internal view returns(uint percent, uint fee) {
        require(_price >= 0, "Invalid price.");

        percent = _percentFee;

        // No data, set it to default
        if (_percentFee == 0) {
            percent = defaultPercentFee;
        }

        // Special value to set it to zero
        if (_percentFee == NO_FEE) {
            percent = 0;
            fee = 0;
        } else {
            fee = _safeMul(_price, percent) / 10000; // adjust for percent and decimal. division always truncate
        }
    }

    // get custom fee hash
    function _getHash(address _currency, address _buyer, address _seller, address _token) internal pure returns(bytes32 key) {
        key = keccak256(abi.encodePacked(_currency, _buyer, _seller, _token));
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
