# Escrow

## Specification

The escrow contract acts as a trusted intermediary between a buyer and a seller, aiming to protect the buyer from the possible non-delivery of the purchased goods. 

The seller initializes the contract by setting: 
- the buyer's address;
- the amount of native cryptocurrency required as a payment.

Immediately after the initialization, the contract supports a single action:
- **deposit**, which allows the buyer to deposit the required amount in the contract.

Once the deposit action has been performed, exactly one of the following actions is possible:
- **pay**, which allows the buyer to transfer the whole contract balance to the seller.
- **refund**, which allows the seller to transfer back the whole contract balance to the buyer.

## Required functionalities

- Native tokens
- Transaction revert

## Implementation

### Initialization

The initialization process is divided into two distinct phases: the `init` function and the subsequent `initialize` step (where escrow-specific data, such as the `buyer` and the required `amount_required`, is registered within the contract)

```move
public fun initialize (buyer: address, amount_required: u64, escrow: &mut Escrow, ctx: &mut TxContext){
    assert!(escrow.seller == ctx.sender(), EPermissionDenied);
    assert!(escrow.state == INIT, EPermissionDenied);
    escrow.buyer = buyer;
    escrow.amount_required = amount_required;
    escrow.state = IDLE;
}
```

Upon initialization, the escrow contract enters the IDLE state, signaling that the `amount` (specified in the `amount_required` field of the Escrow struct) is now available for deposit.

### Deposit

```move
public fun deposit(amount: Coin<IOTA>, escrow: &mut Escrow, ctx: &mut TxContext){
    assert!(ctx.sender() == escrow.buyer, EPermissionDenied);
    assert!(escrow.amount_required == amount.value(), EWrongAmount);
    assert!(escrow.state == IDLE, EPermissionDenied);

    let amount = coin::into_balance(amount);
    escrow.amount.join(amount);
    escrow.state = ACTIVE;
}
```

The buyer can deposit funds only if the contract is in the IDLE state and the deposited `amount` matches the `amount_required`. Upon successful `deposit`, the contract transitions to the ACTIVE state, enabling payment and refund functions.

### Pay and Refund

The `pay` and `refund` functions share identical core logic but differ in direction and permissions:
- Refund: Returns funds to the `buyer` (callable only by the `seller`).
- Pay: Transfers funds to the `seller` (callable only by the `buyer`).

In fact, a helper function `send_balance` can be implemented. 
```move
fun send_balance(recipient: address, escrow: Escrow, ctx: &mut TxContext){
    assert!(escrow.state == ACTIVE, EPermissionDenied);

    let Escrow {id: id, buyer: _, seller: _, amount_required: _, amount: balance, state: _} = escrow;
    let coin = coin::from_balance(balance, ctx);
    transfer::public_transfer(coin, recipient);   
    object::delete(id);
}
```

This function is invoked by both `pay` and `refund`, with the respective receiver address passed as an argument.

```move
public fun pay(escrow: Escrow, ctx: &mut TxContext){
    assert!(escrow.buyer == ctx.sender(), EPermissionDenied);

    send_balance(escrow.seller, escrow, ctx);
}

public fun refund(escrow: Escrow, ctx: &mut TxContext){
    assert!(escrow.seller == ctx.sender(), EPermissionDenied);

    send_balance(escrow.buyer, escrow, ctx);
}
```

## Implementation differences

The Escrow implementation retains the same discrepancies with other dialets identified in the previous implementations.
