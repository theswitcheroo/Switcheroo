pragma solidity ^0.4.18;
import "SimplePurchase.sol";

//----------------------------------------------------------------
//FACTORY CONTRACT - Master contract that creates individual purchase contracts

//Info on mapping found here: https://ethereum.stackexchange.com/questions/9893/how-does-mapping-in-solidity-work#9894
//Info on contract creation: http://solidity.readthedocs.io/en/develop/contracts.html

contract PurchaseCreator {
    struct PurchaseData {
        address seller;
        uint txnValue;
        //address buyer;
        //TODO check if we can pass buyer from child contract back to the mapping
    }

    //Mapping Transaction ID's to each transaction so we can easily track later
    uint public nextPurchaseId;
    mapping(uint => PurchaseData) public purchases;

    //Set variables for pausing contract (pauseContract) function
    bool private stopped = false;
    address public owner;

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
    //TODO make sure we are original msg.sender of the PurchaseCreator, and that this doesn't change
    function PurchaseCreator() public {
        owner = msg.sender;
    }

    //Creates new struct value & ties it to a PurchaseId key in the mapping
    /*function newPurchaseLog(address seller, uint txnValue) isActive public returns (uint PurchaseId) {
        PurchaseId = nextPurchaseId++;
        seller = msg.sender;
        purchases[PurchaseId] = PurchaseData(seller, txnValue);

        return PurchaseId;
    }*/

    //Creates new Purchase child contract with the PurchaseId
    //Can use PurchaseId in the child contract to pull in PurchaseData struct
    function newSimplePurchaseContract(address seller, uint txnValue) isActive public payable returns (SimplePurchase _newPurch, uint PurchaseId) {

        //Increment PurchaseId
        PurchaseId = nextPurchaseId++;
        seller = msg.sender;
        txnValue = msg.value;
        purchases[PurchaseId] = PurchaseData(seller, txnValue);

        _newPurch = (new SimplePurchase).value(txnValue)(seller, PurchaseId);

        return(_newPurch, PurchaseId);
    }

    //Pause contract operation
    function pauseContract() isAdmin public {
        stopped = !stopped;
    }
}