# Simple transfer

## Specification 

The contract allows a user (the *owner*) to deposit native cryptocurrency, 
and another user (the *recipient*) to withdraw arbitrary fractions of the contract balance.

At contract creation, the owner specifies the receiver's address.

After contract creation, the contract supports two actions:
- **deposit** allows the owner to deposit an arbitrary amount of native cryptocurrency in the contract;
- **withdraw** allows the receiver to withdraw any amount of the cryptocurrency deposited in the contract.

## Required functionalities

- Native tokens
- Transaction revert

## Simpe Transfer implementation

### Initialization

```move
fun init( ctx: &mut TxContext){
    let wallet = Wallet {
        id: object::new(ctx),
        balance: balance::zero<IOTA>(),
        owner: ctx.sender(),
        receiver: ctx.sender(),
        initialized: false
    };
    transfer::share_object(wallet);
} 
```

In the IOTA Move framework, the [init](https://docs.iota.org/developer/iota-101/move-overview/init) function is restricted to two parameters: ctx (the transaction context) and optionally otw (the one-time witness). Due to this design, the wallet's owner cannot specify a receiver's address during deployment. This is enforced by the `initialized` flag in the Wallet struct, which is explicitly set to false at deployment time, requiring subsequent initialization for address configuration.

### Set receiver

```move
public fun set_receiver(receiver: address,wallet: &mut Wallet, ctx: &mut TxContext){
    assert!(!wallet.initialized, EPermissionsDenied);
    assert!(ctx.sender() == wallet.owner, EPermissionsDenied);

    wallet.receiver = receiver;
    wallet.initialized = true;
}
```

The `set_receiver` function is designed to allow exclusively the wallet owner to assign a receiver address. This action is restricted to a single execution through two critical safeguards:

1. A first-time-use assertion (!initialized) ensures the function can only run once.
2. An ownership verification assert guarantees only the wallet owner can invoke it.

If both conditions are satisfied, the function:

- Assigns the owner-specified receiver address
- Sets the `initialized` flag to `true`

Once executed, the `initialized` flag permanently blocks re-invocation of `set_receiver`, preventing unauthorized or duplicate modifications to the receiver address.

### Deposite

