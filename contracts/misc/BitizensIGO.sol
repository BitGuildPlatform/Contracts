pragma solidity ^0.4.22;

import "../lib/Ownable.sol";
import "../BitGuildToken.sol";
import "../lib/SafeMath.sol";


/*
 * @dev: Accepts PLAT for purchasing tickets to redeem limited edition pre-sale sets.
 *       No actual transfer is taking place.
 */
contract BitizensIGO is Ownable {
    using SafeMath for uint256;

    event TicketSold(address _buyer, uint _setId, uint _serial);

    // Predefined PLAT token
    BitGuildToken public token = BitGuildToken(0x7E43581b19ab509BCF9397a2eFd1ab10233f27dE); // Main Net

    // Discount for gas price in PLAT
    uint public discount = 50 * 1e18;

    mapping(uint256 => uint256) public setIdToPrice;    // price for the set
    mapping(uint256 => uint256) public setIdToQty;      // no of sets left
    mapping(uint256 => uint256) public setIdToSerial;   // return the next serial no.

    /// @dev Constructor. Create hardcoded set info with price
    constructor() public {
        // Price in PLAT
        setIdToPrice[16] = 180000 * 1e18;      //  3.0 Eth
        setIdToPrice[17] = 60000 * 1e18;       //  0.5 Eth
        setIdToPrice[18] = 480000 * 1e18;      //  8.0 Eth
        setIdToPrice[19] = 3000000 * 1e18;     // 50.0 Eth
        setIdToPrice[20] = 720000 * 1e18;      // 12.0 Eth

        setIdToQty[16] = 25;
        setIdToQty[17] = 100;
        setIdToQty[18] = 10;
        setIdToQty[19] = 1;
        setIdToQty[20] = 3;

        setIdToSerial[16] = 1;
        setIdToSerial[17] = 1;
        setIdToSerial[18] = 1;
        setIdToSerial[19] = 1;
        setIdToSerial[20] = 1;
    }

    /// @dev fall back function
    function () external payable {
        revert();
    }

    /// @dev qty left for a set
    function getQty(uint _setId) public view returns(uint) {
        return setIdToQty[_setId];
    }

    /// @dev the price for a set
    function getPrice(uint _setId) public view returns(uint) {
        return setIdToPrice[_setId];
    }

    /// @dev returns the next serial number
    function getSerialNo(uint _setId) public view returns(uint) {
        return setIdToSerial[_setId];
    }

    /// @dev Admin function: make all bundles unavailable. only owner can run
    function endIGO() public onlyOwner {
        uint tokensLeft = token.balanceOf(this);
        token.transfer(msg.sender, tokensLeft);
        _clearData();
    }

    /// @dev function that is called when trying to use PLAT for payments from approveAndCall
    function receiveApproval(address _sender, uint256 _value, BitGuildToken _tokenContract, bytes _extraData) public {
        /// @dev Make sure approveAndCall comes from the official BitGuildToken contract
        require(
            msg.sender == address(token),
            "Unauthorized contract address."
        );

        require(
            _extraData.length != 0,
            "No extraData provided."
        );

        // convert setId back to uint
        uint setId = _bytesToUint(_extraData);

        // make sure set is availabe before charging
        require(
            setIdToQty[setId] > 0,
            "Set is not found or no longer available."
        );

        // check if set has price and has correct price
        require(
            setIdToPrice[setId] == _value + discount,
            "Invalid price"
        );

        // Transfer PLAT to service contract
        require(
            _tokenContract.transferFrom(_sender, address(this), _value),
            "Approved PLAT transfer failed."
        );

        // update mapping
        uint serialNo = setIdToSerial[setId];
        // Update mappings
        setIdToQty[setId] = setIdToQty[setId].sub(1);
        setIdToSerial[setId] = serialNo.add(1);

        // Emit event
        emit TicketSold(msg.sender, setId, serialNo);
    }

    /// @dev set all hardcoded items to 0 available
    function _clearData() internal {
        setIdToQty[16] = 0;
        setIdToQty[17] = 0;
        setIdToQty[18] = 0;
        setIdToQty[19] = 0;
        setIdToQty[20] = 0;
    }

    /// @dev helper function to convert bytes back to uint256
    function _bytesToUint(bytes _b) internal pure returns(uint256) {
        uint256 number;
        for (uint i=0; i < _b.length; i++) {
            number = number + uint(_b[i]) * (2**(8 * (_b.length - (i+1))));
        }
        return number;
    }
}
