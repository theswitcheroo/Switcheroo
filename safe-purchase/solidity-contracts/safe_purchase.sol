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
    uint public value;
    address public seller;
    address public buyer;
    enum State { Created, Locked, Disputed, Unlocked, Complete, Inactive }
    State public state;
    uint public PurchaseId;

    function Purchase() payable {
        buyer = msg.sender; //this needs to be changed now that we are having seller initiate
        value = msg.value;
        state = State.Created;
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

    modifier inState(State _state) {
        require(state == _state);
        _;
    }

    event Aborted();
    event PurchaseApproved();
    event ItemDelivered();
    event ItemAccepted();

    /// Abort the purchase and reclaim the ether.
    /// Can only be called by the buyer before
    /// the contract is locked.
    function abort()
        onlyBuyer //this needs to be changed since seller is initiating
        inState(State.Created)
    {
        Aborted();
        state = State.Inactive;
        buyer.transfer(this.balance);
    }

    /// Approve the purchase as seller.
    /// The ether will be locked until confirmItemQuality
    /// is called.
    function approvePurchase()
        inState(State.Created)
        onlySeller
        condition(msg.value == value)
        payable
    {
        PurchaseApproved();
        seller = msg.sender;
        state = State.Locked;
    }

    /// Buyer confirms item is what they wanted.
    /// This will release the locked ether.
    function confirmItemQuality()
        onlyBuyer
        inState(State.Locked)
    {
        ItemAccepted();
        // It is important to change the state first because
        // otherwise, the contracts called using `send` below
        // can call in again here.
        state = State.Unlocked;

        /* WARNING: this function may allow buyer to call
        multiple times and withdraw more than their deposit.
        NEEDS MORE RESEARCH!!

        Withdraw must take into account shipping fee,
        switcheroo fee, and any punishments
        */

        buyer.transfer(value);
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
    uint nextPurchaseId;
    mapping(uint => PurchaseData) purchases; //should we use uint256 instead of uint?

    function newPurchase (address buyer, address seller, uint value) returns (uint PurchaseId) {
        address newPurchase = new Purchase(); //creates new instance of Purchase contract I think

        //Below attempts to create a struct for the new Purchase contract with
        //info that can be easily looked up using the PurchaseId
        var purchase = purchases[nextPurchaseId];
        purchase.buyer = buyer;
        purchase.seller = seller;
        purchase.value = value;
        nextPurchaseId ++;
        PurchaseId = nextPurchaseId;

    }

}
