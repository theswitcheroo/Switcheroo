pragma solidity ^0.4.18;
import "PurchaseCreator.sol";

//------------------------------------------------------------------------
//CHILD CONTRACT
contract SimplePurchase {
    uint public txnValue;
    address public seller;
    address public buyer;
    address public admin;
    enum Status {initialized, locked, seller_canceled, delivered, inactive}
    Status public status;
    uint public PurchaseId; //QUESTION how do I pass this through from parent?


    function SimplePurchase()
        public
        payable
    {
        require(msg.value > 0);
        txnValue = msg.value;
        seller = msg.sender;
        admin = 0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB;
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

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    modifier requireStatus(Status _status) {
        require(status == _status);
        _;
    }

    event Aborted();
    event PurchaseApproved();
    event SellerCanceled();
    event ItemDelivered();
    event BuyerPayout();
    event SellerPayout();

    /*function checkBalance() view public returns(uint) {
        uint currentBalance = this.balance;
        return(currentBalance);
    }*/

    function inState(Status _status) view private returns(Status) {
        status == _status;
        return status;
    }

    /// Abort the purchase and reclaim the ether.
    /// Can only be called by the seller before
    /// the contract is locked.
    function abort()
        onlySeller
        requireStatus(Status.initialized)
        public
    {
        Aborted();
        status = Status.inactive;

        uint _balance = this.balance;
        _balance = 0;
        seller.transfer(_balance);
    }

    /// Approve the purchase as buyer.
    /// The ether will be locked until state is changed by admin
    function acceptPurchaseTerms()
        requireStatus(Status.initialized)
        condition(msg.value == txnValue)
        payable
        public
    {
        PurchaseApproved();
        buyer = msg.sender;
        status = Status.locked;
    }

    // This sets status to allow seller withdrawal
    function setStatusDelivered()
        onlyAdmin
        requireStatus(Status.locked)
        public
    {
        ItemDelivered();
        status = Status.delivered;
    }

    // Seller failed to mail item within 72 hrs of buyer locking money
    //TODO can calculate this on chain so we avoid a new call
    function setStatusSellerCanceled()
        onlyAdmin
        requireStatus(Status.locked)
        public
    {
        SellerCanceled();
        status = Status.seller_canceled;
    }

    // Allows buyer to withdraw funds depending on the terminal state
    function withdrawBuyerFunds() //TODO test that this can't be called during a status it shouldn't be (e.g. initialized)
        onlyBuyer
        requireStatus(Status.seller_canceled)
        public
    {
        // Check that this func hasn't already been called for this txn
        require(this.balance != 0);

        // Run payout calculations & zero out balances
        uint _balance = this.balance;


        // Transfer payouts
        buyer.transfer(_balance);
        _balance = 0;
        BuyerPayout();
    }

    // Allows seller to withdraw funds depending on the terminal state
    function withdrawSellerFunds()
        onlySeller
        requireStatus(Status.delivered)
        public
    {
        // Check that this func hasn't already been called for this txn
        require(this.balance != 0);

        // Run payout calculations & zero out balances
        uint _balance = this.balance;


        // Transfer payouts
        seller.transfer(_balance);
        _balance = 0;
        SellerPayout();
    }

}
