pragma solidity ^0.4.24;


/**
 * @title BitGuildAccessAdmin
 * @dev Allow two roles: 'owner' and 'operator'
 *      - owner: admin/superuser with financial rights
 *      - operator: can update configurations
 */
contract BitGuildAccessAdmin {
    address public owner;
    uint public totalOperators = 0;

    mapping(address => bool) public isOperator;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event OperatorAdded(address operator);
    event OperatorRemoved(address operator);

    /**
     * @dev The BitGuildAccessAdmin constructor: sets owner to the sender account
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Throws if called by any non-operator account.
     */
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
            "Invalid new owner address"
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
            "Invalid new operator address"
        );

        // safe math
        totalOperators++;
        require(
            totalOperators > 0,
            "Overflow."
        );

        isOperator[_newOperator] = true;
        emit OperatorAdded(_newOperator);
    }

    /**
     * @dev Allows the current owner or operators to remove operator
     * @param _operator Address of the operator to be removed
     */
    function removeOperator(address _operator) public onlyOwnerOrOperator {
        require(
            _operator != address(0),
            "Invalid operator address"
        );
        require(
            isOperator[_operator],
            "Not an operator."
        );

        // safe math
        totalOperators--;
        require(
            totalOperators > 0,
            "Overflow."
        );
        isOperator[_operator] = false;
        emit OperatorRemoved(_operator);
    }
}
