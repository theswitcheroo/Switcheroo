pragma solidity ^0.4.18;
import "./SimplePurchase.sol";

//----------------------------------------------------------------
//FACTORY CONTRACT - Master contract that creates individual purchase contracts

//Info on mapping: https://ethereum.stackexchange.com/questions/9893/how-does-mapping-in-solidity-work#9894
//Info on contract creation: http://solidity.readthedocs.io/en/develop/contracts.html

contract PurchaseCreator {

    //Create struct to hold txn data
    struct PurchaseData {
        address seller;
        uint txnValue;
    }

    //Mapping Transaction ID's to each transaction so we can easily track later
    uint public nextPurchaseId;
    mapping(uint => PurchaseData) public purchases;

    //Set variables for pausing contract (pauseContract) function
    bool private stopped = false;
    address public owner;

    //Enforce ownership for admin only functions
    modifier isAdmin() {
        require(msg.sender == owner);
        _;
    }

    //Enforce pause button function
    modifier isActive() {
        require(stopped == false);
        _;
    }

    //Set Switcheroo as owner of contract
    function PurchaseCreator() public {
        owner = msg.sender;
    }

    //Creates new Purchase child contract with a PurchaseId
    function newSimplePurchaseContract(address seller, uint txnValue) isActive public payable returns (SimplePurchase _newPurch, uint PurchaseId) {

        //Increment PurchaseId, set values for PurchaseData struct
        PurchaseId = nextPurchaseId++;
        seller = msg.sender;
        txnValue = msg.value;
        purchases[PurchaseId] = PurchaseData(seller, txnValue);

        //Create new SimplePurchase child contract
        _newPurch = (new SimplePurchase).value(txnValue)(seller, PurchaseId);

        return(_newPurch, PurchaseId);
    }

    //Pause contract operation
    function pauseContract() isAdmin public {
        stopped = !stopped;
    }
}
