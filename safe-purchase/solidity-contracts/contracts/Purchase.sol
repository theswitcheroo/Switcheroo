pragma solidity ^0.4.18;

// To do
// Delivery confirmation function
// Front end interaction hooks?
// Check final withdraws for security holes
// Add in dispute function for buyer
// Add in deposits - currently just txn value
// Add deny function for seller if txn value isn't agreed upon
// Setup for master & child contracts

//------------------------------------------------------------------------
//CHILD CONTRACT
contract Purchase {
    // Admin?
    uint public price;
    uint public shipping_cost;
    uint public shipping_cost_return;
    uint public deposit_buyer;
    uint public deposit_seller;
    uint public fee_buyer;
    uint public fee_seller;
    address public seller;
    address public buyer;
    enum Status {initialized, locked, seller_canceled, disputed, delivered, dispute_canceled, return_delivered, completed, inactive}
    Status public status;
    uint public PurchaseId;

    // TODO: Lookup value passthroughs from parent.
    function Purchase() public payable {
        seller = PurchaseCreator.seller;
        // buyer = PurchaseCreator.buyer;
        price = PurchaseCreator.price;
        deposit_seller = price * 0.1; // May want to calculate based on price
        fee_seller = price * .01; // Decimal's?
        status = Status.initialized;
    }

    modifier condition(bool _condition) {
        require(_condition);
        _;
    }

    modifier onlyBuyer() {
        require(msg.sender == buyer);
        _;
    }

    modifier onlySeller() {
        require(msg.sender == seller);
        _;
    }

    modifier requireState(Status _status) {
        require(status == _status);
        _;
    }

    event Aborted();
    event PurchaseApproved();
    event ItemDelivered();
    event ItemAccepted();

    // TODO: constant ??
    function inState(Status _status) constant bool {
        return status == _status;
    }

    /// Abort the purchase and reclaim the ether.
    /// Can only be called by the seller before
    /// the contract is locked.
    function abort()
        onlySeller
        requireState(Status.initialized)
    {
        // TODO: decide where to put events in functions
        Aborted();
        state = State.inactive;

        uint balance = this.balance;
        this.balance = 0;
        seller.transfer(balance);
    }

    /// Approve the purchase as buyer.
    /// The ether will be locked until confirmItemQuality
    /// is called.
    function acceptPurchaseTerms()
        requireState(Status.initialized)
        onlyBuyer
        condition(msg.value == value) // TODO: confirm value conditions
        payable
    {
        PurchaseApproved();
        buyer = msg.sender;
        state = State.Locked;
    }

    /// This will release the locked ether.
    function setStatusDelivered()
        // TODO: only admin?
        requireState(Status.locked)
    {
        ItemAccepted();
        state = State.delivered;
    }

    function setStatusReturnDelivered()
    {
    }

    function setStatusSellerCanceled()
    {
    }

    function setStatusDisputeCanceled()
    {
    }

    function setStatusDisputed()
    {
    }

    function withdrawBuyerFunds()
        onlyBuyer
    {
      if (inState(Status.delivered)) {
        _buyer_deposit = buyer_deposit; // TODO: Check underscore'd variables
        buyer_deposit = 0;
        buyer.transfer(_buyer_deposit);
      } else if (inState(Status.return_delivered)) {

      } else if (inState(Status.dispute_canceled)) {

      } else if (inState(Status.dispute_canceled)) {

      } else {
        return false;
      }
    }

    function withdrawSellerFunds()
    {
    }

    function withdrawSwitcherooFunds()
    {
    }


    // Seller withdraws payment for item
    // Transaction is complete, contract locked
    function getPaid()
        onlySeller
        inState(State.Unlocked)
    {
        state = State.Complete;

        seller.transfer(this.balance);
    }
}

//----------------------------------------------------------------
//PARENT CONTRACT - Master contract that creates individual purchase contracts

//Info on mapping found here: https://ethereum.stackexchange.com/questions/9893/how-does-mapping-in-solidity-work#9894
//Info on contract creation: http://solidity.readthedocs.io/en/develop/contracts.html

//I have no fucking idea if I did this right
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
