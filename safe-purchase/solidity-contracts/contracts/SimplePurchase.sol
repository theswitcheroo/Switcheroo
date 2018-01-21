pragma solidity ^0.4.18;
import "./PurchaseCreator.sol";

//------------------------------------------------------------------------
//CHILD CONTRACT
contract SimplePurchase {
    uint public txnValue;
    address public _seller;
    address public buyer;
    address public admin;
    enum Status {initialized, locked, seller_canceled, delivered, inactive}
    Status public status;
    uint public _PurchaseId;


    function SimplePurchase(address seller, uint PurchaseId)
        public
        payable
    {
        require(msg.value > 0);
        txnValue = msg.value;
        _seller = seller;
        admin = 0x627306090abaB3A6e1400e9345bC60c78a8BEf57;
        status = Status.initialized;
        _PurchaseId = PurchaseId;
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
        require(msg.sender == _seller);
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
        _seller.transfer(_balance);
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
    function withdrawBuyerFunds()
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
        _seller.transfer(_balance);
        _balance = 0;
        SellerPayout();
    }

}
