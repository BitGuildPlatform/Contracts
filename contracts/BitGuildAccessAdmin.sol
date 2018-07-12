pragma solidity ^0.4.24;


/**
 * @title BitGuildAccessAdmin
 * @dev Allow two roles: 'owner' or 'operator'
 *      - owner: admin/superuser (e.g. with financial rights)
 *      - operator: can update configurations
 */
contract BitGuildAccessAdmin {
    address public owner;
    address[] public operators;

    uint public MAX = 10; // Default maximum number of operators allowed

    mapping(address => bool) public isOperator;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event OperatorAdded(address operator);
    event OperatorRemoved(address operator);

    /// @dev The BitGuildAccessAdmin constructor: sets owner to the sender account
    constructor() public {
        owner = msg.sender;
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /// @dev Throws if called by any non-operator account.
    modifier onlyOperator() {
        require(isOperator[msg.sender]);
        _;
    }

    modifier onlyOwnerOrOperator() {
        require(
            isOperator[msg.sender] || msg.sender == owner,
            "Permission denied. Must be an operator or the owner."
        );
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(
            _newOwner != address(0),
            "Invalid new owner address."
        );
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    /**
     * @dev Allows the current owner or operators to add operators
     * @param _newOperator New operator address
     */
    function addOperator(address _newOperator) public onlyOwnerOrOperator {
        require(
            _newOperator != address(0),
            "Invalid new operator address."
        );

        // Make sure no dups
        require(
            !isOperator[_newOperator],
            "New operator exists."
        );

        // Only allow so many ops
        require(
            operators.length < MAX,
            "Overflow."
        );

        operators.push(_newOperator);
        isOperator[_newOperator] = true;

        emit OperatorAdded(_newOperator);
    }

    /**
     * @dev Allows the current owner or operators to remove operator
     * @param _operator Address of the operator to be removed
     */
    function removeOperator(address _operator) public onlyOwnerOrOperator {
        // Make sure operators array is not empty
        require(
            operators.length > 0,
            "No operator."
        );

        // Make sure the operator exists
        require(
            isOperator[_operator],
            "Not an operator."
        );

        // Manual array manipulation:
        // - replace the _operator with last operator in array
        // - remove the last item from array
        address lastOperator = operators[operators.length - 1];
        for (uint i = 0; i < operators.length; i++) {
            if (operators[i] == _operator) {
                operators[i] = lastOperator;
            }
        }
        operators.length -= 1; // remove the last element

        isOperator[_operator] = false;
        emit OperatorRemoved(_operator);
    }

    /// @dev Remove ALL operators
    function removeAllOps() public onlyOwner {
        for (uint i = 0; i < operators.length; i++) {
            isOperator[operators[i]] = false;
        }
        operators.length = 0;
    }

    /// @dev Get number of operators
    function opsCount() public view returns(uint count) {
        return operators.length;
    }

    /// @dev Return all operator addresses
    function getAllOps() public onlyOwnerOrOperator view returns(address []) {
        return operators;
    }

    /**
     * @dev Update maximum allowed operators
     * @param _newMax new maximum number of operators
     */
    function updateMax(uint _newMax) public onlyOwner {
        require(
            _newMax > 0 && _newMax < 1000,
            "Allowed max is between 1 and 999."
        );
        MAX = _newMax;
    }
}
