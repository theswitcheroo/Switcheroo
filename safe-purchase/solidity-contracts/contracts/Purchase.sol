pragma solidity ^0.4.18;
import "Purchase_Factory.sol";

// To do
// Delivery confirmation function - DONE
// Front end interaction hooks? - Handled by web3
// Add final withdraws - DONE
// Add in dispute function for buyer - DONE
// Add in deposits - currently just txn value
// Setup for master & child contracts

//------------------------------------------------------------------------
//CHILD CONTRACT
contract Purchase {
    uint public initialValue;
    uint public price;
    uint public shipping_cost;
    uint public shipping_cost_return;
    uint public deposit_buyer;
    uint public deposit_seller;
    uint public fee_buyer;
    uint public fee_seller;
    address public seller;
    address public buyer;
    address public admin;
    enum Status {initialized, locked, seller_canceled, disputed, delivered,
        dispute_canceled, return_delivered, completed, inactive}
    Status public status;
    uint public PurchaseId;

    // TODO: Lookup value passthroughs from parent.
    // Do we pass through seller payment from parent?
    function Purchase()
        public
        payable
    {
        require(msg.value > 0);
        initialValue = msg.value;
        seller = msg.sender;
        //admin = ?? TODO - figure out how to set us as admin
        price = PurchaseCreator.price;
        fee_seller = 1;
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
    event ItemAccepted(); //still need this?
    event BuyerDisputed();
    event DisputeCanceled();
    event ReturnDelivered();
    event BuyerPayout();
    event SellerPayout();
    event AdminPayout();

    // TODO: constant ?? See here: http://solidity.readthedocs.io/en/develop/contracts.html?view-functions#view-functions
    function inState(Status _status) constant bool {
        return status == _status;
    }

    /// Abort the purchase and reclaim the ether.
    /// Can only be called by the seller before
    /// the contract is locked.
    function abort()
        onlySeller
        requireStatus(Status.initialized)
    {
        // TODO: decide where to put events in functions
        Aborted();
        status = Status.inactive;

        uint balance = this.balance;
        this.balance = 0;
        seller.transfer(balance);
    }

    /// Approve the purchase as buyer.
    /// The ether will be locked until state is changed by admin
    function acceptPurchaseTerms()
        requireStatus(Status.initialized)
        onlyBuyer
        condition(msg.value == value) // TODO: confirm value conditions
        payable
    {
        PurchaseApproved();
        buyer = msg.sender;
        status = Status.locked;
    }

    // This will release the locked ether.
    function setStatusDelivered()
        onlyAdmin
        requireStatus(Status.locked)
    {
        ItemAccepted();
        state = State.delivered;
    }

    // Disputed item has been returned to seller
    function setStatusReturnDelivered()
        onlyAdmin
        requireStatus(Status.disputed)
    {
        ReturnDelivered();
        status = Status.return_delivered;
    }

    // Seller failed to mail item within 72 hrs of buyer locking money
    function setStatusSellerCanceled()
        onlyAdmin
        requireStatus(Status.locked)
    {
        SellerCanceled();
        status = Status.seller_canceled;
    }

    // Buyer failed to mail returned item within 72 hrs of disputing
    function setStatusDisputeCanceled()
        onlyAdmin
        requireStatus(Status.disputed)
    {
        DisputeCanceled();
        status = Status.dispute_canceled;
    }

    // Buyer disputed item quality
    function setStatusDisputed()
        onlyAdmin //TODO decide if we are letting buyer do this or only us
        requireStatus(Status.locked)
    {
        BuyerDisputed();
        status = Status.disputed
    }

    // Allows buyer to withdraw funds depending on the terminal state
    function withdrawBuyerFunds() //test that this can't be called during a status it shouldn't be (e.g. initialized)
        onlyBuyer
    {
        if (inState(Status.delivered)) {
            // Check that this func hasn't already been called for this txn
            require(deposit_buyer != 0);
            require(shipping_cost != 0);
            require(fee_buyer != 0);

            // Run payout calculations & zero out balances
            _buyer_payout = deposit_buyer - shipping_cost - fee_buyer;
            _admin_payout = shipping_cost + fee_buyer;
            deposit_buyer = 0;
            shipping_cost = 0;
            fee_buyer = 0;

            // Transfer payouts
            admin.transfer(_admin_payout);
            buyer.transfer(_buyer_payout);

        } else if (inState(Status.return_delivered)) {
            // Check that this func hasn't already been called for this txn
            require(deposit_buyer != 0);
            require(shipping_cost != 0);
            require(fee_buyer != 0);
            require(price != 0);

            // Run payout calculations & zero out balances
            _buyer_payout = deposit_buyer + price - shipping_cost - fee_buyer;
            _admin_payout = shipping_cost + fee_buyer;
            deposit_buyer = 0;
            price = 0;
            shipping_cost = 0;
            fee_buyer = 0;

            // Transfer payouts
            admin.transfer(_admin_payout);
            buyer.transfer(_buyer_payout);

        } else if (inState(Status.dispute_canceled)) {
            // Check that this func hasn't already been called for this txn
            require(deposit_buyer != 0);
            require(shipping_cost != 0);
            require(fee_buyer != 0);
            require(shipping_cost_return != 0);

            // Run payout calculations & zero out balances
            _buyer_payout = deposit_buyer - shipping_cost - shipping_cost_return - fee_buyer;
            _admin_payout = shipping_cost + shipping_cost_return + fee_buyer;
            deposit_buyer = 0;
            shipping_cost_return = 0;
            shipping_cost = 0;
            fee_buyer = 0;

            // Transfer payouts
            admin.transfer(_admin_payout);
            buyer.transfer(_buyer_payout);

        } else if (inState(Status.seller_canceled)) {
            // Check that this func hasn't already been called for this txn
            require(deposit_buyer != 0);
            require(price != 0);

            // Run payout calculations & zero out balances
            _buyer_payout = deposit_buyer + price;
            deposit_buyer = 0;
            price = 0;

            // Transfer payouts
            buyer.transfer(_buyer_payout);

        } else {
            revert; //changed from "return false" to properly throw error & save gas
            //see link here: http://solidity.readthedocs.io/en/develop/control-structures.html?highlight=require#error-handling-assert-require-revert-and-exceptions
        }

        BuyerPayout();
    }

    // Allows seller to withdraw funds depending on the terminal state
    function withdrawSellerFunds()
        onlySeller
    {
        if(inState(Status.delivered)) {
            // Check that this func hasn't already been called for this txn
            require(deposit_seller != 0);
            require(price != 0);
            require(fee_seller != 0);

            // Run payout calculations & zero out balances
            _seller_payout = price + deposit_seller - fee_seller;
            _admin_payout = fee_seller;
            price = 0;
            deposit_seller = 0;
            fee_seller = 0;

            // Transfer payouts
            admin.transfer(_admin_payout);
            seller.transfer(_seller_payout);

        } else if(inState(Status.return_delivered)) {
            // Check that this func hasn't already been called for this txn
            require(deposit_seller != 0);
            require(shipping_cost_return != 0);
            require(fee_seller != 0);

            // Run payout calculations & zero out balances
            _seller_payout = deposit_seller - fee_seller - shipping_cost_return;
            _admin_payout = fee_seller + shipping_cost_return;
            deposit_seller = 0;
            fee_seller = 0;
            shipping_cost_return = 0;

            // Transfer payouts
            admin.transfer(_admin_payout);
            seller.transfer(_seller_payout);

        } else if(inState(Status.dispute_canceled)) {
            // Check that this func hasn't already been called for this txn
            require(deposit_seller != 0);
            require(price != 0);
            require(fee_seller != 0);

            // Run payout calculations & zero out balances
            _seller_payout = price + deposit_seller - fee_seller;
            _admin_payout = fee_seller;
            price = 0;
            deposit_seller = 0;
            fee_seller = 0;

            // Transfer payouts
            admin.transfer(_admin_payout);
            seller.transfer(_seller_payout);

        } else if(inState(Status.seller_canceled)) {
            // Check that this func hasn't already been called for this txn
            require(deposit_seller != 0);
            require(shipping_cost != 0);
            require(fee_seller != 0);

            // Run payout calculations & zero out balances
            _seller_payout = deposit_seller - fee_seller - shipping_cost;
            _admin_payout = fee_seller + shipping_cost;
            deposit_seller = 0;
            fee_seller = 0;
            shipping_cost = 0;

            // Transfer payouts
            admin.transfer(_admin_payout);
            seller.transfer(_seller_payout);

        } else {
            revert;
        }

        SellerPayout();
    }

}
