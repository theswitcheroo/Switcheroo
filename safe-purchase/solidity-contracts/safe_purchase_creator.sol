pragma solidity ^0.4.18;

//Info on mapping found here: https://ethereum.stackexchange.com/questions/9893/how-does-mapping-in-solidity-work#9894
//Info on contract creation: http://solidity.readthedocs.io/en/develop/contracts.html

//Master contract that creates individual purchase contracts
//Should I be using a struct here? Does the struct replace a contract? If so is the struct less powerful?
contract TransactionCreator {
    struct TransactionData {
        address public buyer;
        address public seller;
        uint public value;
    }

    //Mapping Transaction ID's to each transaction so we can easily track later
    uint nextTransactionId;
    mapping(uint => TransactionData) transactions;

    function newTransaction (address buyer, address seller, uint value) returns (uint id) {

    }

}
