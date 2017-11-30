pragma solidity ^0.4.18;
import "Purchase.sol";

//----------------------------------------------------------------
//FACTORY CONTRACT - Master contract that creates individual purchase contracts

//Info on mapping found here: https://ethereum.stackexchange.com/questions/9893/how-does-mapping-in-solidity-work#9894
//Info on contract creation: http://solidity.readthedocs.io/en/develop/contracts.html

contract PurchaseCreator {
    struct PurchaseData {
        //address buyer;
        //TODO check if we can pass buyer from child contract back to the mapping
        address seller;
        uint txnValue;
    }

    //Mapping Transaction ID's to each transaction so we can easily track later
    uint public nextPurchaseId;
    mapping(uint => PurchaseData) public purchases;

    //Set variables for pausing contract (pauseContract) function
    bool private stopped = false;
    address private owner;

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
    //QUESTION do we need to make this the constructor function?
    function newPurchaseLog(address seller, uint txnValue) isActive public returns (uint PurchaseId) {
        PurchaseId = nextPurchaseId++;
        purchases[PurchaseId] = PurchaseData(seller, txnValue);

        return PurchaseId;
    }

    //Creates new Purchase child contract with the PurchaseId
    //Can use PurchaseId in the child contract to pull in PurchaseData struct
    function newPurchaseContract(uint PurchaseId) isActive public payable {
        //http://solidity.readthedocs.io/en/develop/control-structures.html#creating-contracts-via-new
        //Above link has example of creating + endowing contract with ether
        Purchase newPurch = (new Purchase).value(purchases[PurchaseId].txnValue)(PurchaseId);
    }

    //Pause contract operation
    function pauseContract() isAdmin public {
        stopped = !stopped;
    }
}
