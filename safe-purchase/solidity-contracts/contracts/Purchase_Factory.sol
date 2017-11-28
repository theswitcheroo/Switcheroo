pragma solidity ^0.4.18;
import "Purchase.sol";

//----------------------------------------------------------------
//FACTORY CONTRACT - Master contract that creates individual purchase contracts

//Info on mapping found here: https://ethereum.stackexchange.com/questions/9893/how-does-mapping-in-solidity-work#9894
//Info on contract creation: http://solidity.readthedocs.io/en/develop/contracts.html

contract PurchaseCreator {
    struct PurchaseData {
        address buyer;
        address seller;
        uint price;
    }

    //Mapping Transaction ID's to each transaction so we can easily track later
    uint public nextPurchaseId;
    mapping(uint => PurchaseData) public purchases;

    //Creates new struct value & ties it to a PurchaseId key in the mapping
    function newPurchase(address buyer, address seller, uint price) returns (uint PurchaseId) {
        PurchaseId = nextPurchaseId++;
        purchases[PurchaseId] = PurchaseData(buyer, seller, price);

        return PurchaseId;
    }

    //Creates new Purchase child contract with the PurchaseId
    //Can use PurchaseId in the child contract to pull in PurchaseData struct
    function newPurchase(uint PurchaseId) payable {
        address newPurch = new Purchase(PurchaseId);
    }
}
