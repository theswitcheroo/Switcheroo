import "Purchase.sol"

//----------------------------------------------------------------
//FACTORY CONTRACT - Master contract that creates individual purchase contracts

//Info on mapping found here: https://ethereum.stackexchange.com/questions/9893/how-does-mapping-in-solidity-work#9894
//Info on contract creation: http://solidity.readthedocs.io/en/develop/contracts.html

contract PurchaseCreator {
    struct PurchaseData {
        address buyer;
        address seller;
        uint value;
    }

    //Mapping Transaction ID's to each transaction so we can easily track later
    uint public nextPurchaseId;
    mapping(uint => PurchaseData) public purchases; //should we use uint256 instead of uint?

    function newPurchase (address buyer, address seller, uint value) returns (uint PurchaseId) {
        //Below attempts to create a struct for the new Purchase contract with
        //info that can be easily looked up using the PurchaseId
        PurchaseData storage purchase = purchases[nextPurchaseId];
        purchase.buyer = buyer;
        purchase.seller = seller;
        purchase.value = value;
        nextPurchaseId ++;
        PurchaseId = nextPurchaseId;

        return new Purchase(); //attempt to create new instance of Purchase contract, but not correct
        return PurchaseId;
    }

    //This is an external getter function to access the data from outside
    //the contract, I think it can be used to check status from web3
    //not sure if useful...

    /*function getPurchaseData(PurchaseData) constant {
        var id = purchases[PurchaseId];
        return (purchases(PurchaseData)[id].buyer, purchases(PurchaseData)[id].seller, purchases(PurchaseData)[id].value);
    }*/

}
