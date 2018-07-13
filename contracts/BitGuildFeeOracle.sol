pragma solidity ^0.4.24;

import "./BitGuildAccessAdmin.sol";


/**
 * @title BitGuildFeeOracle
 * @dev Fee definition
 */
contract BitGuildFeeOracle is BitGuildAccessAdmin {
    /// @dev fixed is not supported. use percent * 100
    uint public percentFee = 300; // Fees bitguild marketplace charges.

    event FeeChanged(uint newPercentFee, uint oldPercentFee, address operator);

    /**
     * @dev Allow operators to update the fee
     * @param _newPercentFee New fee in percent x 100
     */
    function updateFee(uint _newPercentFee) public onlyOperator {
        require(
            _newPercentFee > 0 && _newPercentFee < 10000,
            "Invalid percent fee."
        );

        emit FeeChanged(_newPercentFee, percentFee, msg.sender);
        percentFee = _newPercentFee;
    }

    /**
     * @dev Calculate the fee
     * @param _price Base price for fee calculation
     */
    function getFee(uint _price) public view returns(uint fee) {
        require(
            _price > 0,
            "Invalid price."
        );

        fee = safeMul(_price, percentFee) / 10000; // adjust for percent and decimal. division always truncate
        return fee;
    }

    // safe multiplication
    function safeMul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        assert(c / a == b);
        return c;
    }
}
