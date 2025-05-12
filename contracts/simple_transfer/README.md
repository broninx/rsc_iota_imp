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

```move
public fun deposit(amount: Coin<IOTA>,wallet:&mut Wallet, ctx: &mut TxContext){
    assert!(ctx.sender() == wallet.owner, EPermissionsDenied);
    
    let balance_to_deposite = coin::into_balance<IOTA>(amount);
    wallet.balance.join(balance_to_deposite);
}
```

The deposit function enables the wallet owner to transfer [IOTA](https://docs.iota.org/developer/stardust/units#iota) (the network's native token) into the Wallet. This operation is restricted to the owner, enforced by an initial ownership verification assert in the function’s logic. Upon successful validation, the specified IOTA amount is securely added to the Wallet’s balance.

IOTA coins are wrapped in a [Coin](https://docs.iota.org/references/framework/iota-framework/coin#0x2_coin_Coin) type, which acts as a container for balances. To extract the underlying value, the into_balance function from the [coin module](https://docs.iota.org/references/framework/iota-framework/coin) is invoked, converting the Coin into a balance.
The converted balance (provided by the owner) is then added to the Wallet’s total balance, finalizing the deposit.

### Withdrow

```move
public fun withdrow(amount: u64, wallet: &mut Wallet, ctx: &mut TxContext){
    assert!(ctx.sender() == wallet.receiver, EPermissionsDenied);
    assert!(amount <= wallet.balance.value(), EBiggerThanBalance);

    let withdrow_balance = wallet.balance.split(amount);
    let withdrow_coin = coin::from_balance(withdrow_balance, ctx);
    iota::transfer(withdrow_coin, ctx.sender());
}
```

The withdraw function enables the designated receiver to claim funds from the Wallet’s balance. Its workflow includes:

1. Validation Checks:
   - Receiver Authorization: A primary assertion verifies the caller is the authorized receiver.
   - Balance Sufficiency: A secondary assertion ensures the requested amount does not exceed the available balance.
2. Balance Management: The balance is split into two parts: the portion requested by the receiver and the residual funds retained in the Wallet.
3. Token Conversion: The withdrawal amount (stored as a Balance type) is converted into a Coin using the [from_balance](https://docs.iota.org/references/framework/iota-framework/coin#0x2_coin_from_balance) function, as the Balance type lacks [key abilities](https://docs.iota.org/developer/iota-101/move-overview/structs-and-abilities/key).
4. Funds Transfer: The converted Coin is sent to the receiver using the [transfer](https://docs.iota.org/references/framework/devnet/iota-framework/iota#0x2_iota_transfer) function from the [iota module](https://docs.iota.org/references/framework/devnet/iota-framework/iota), completing the withdrawal.


## Implementation differences

Below there are some of the most important differences in the simple transfer implementation between Move diales like Aptos or SUI, and IOTA.

Init:the init function is a special one-time initialization function that automatically executes during the deployment of a module.
   - **Aptos**: it accepts a &signer parameter (representing the deployer’s address) and is used to set up initial on-chain state, such as creating global resources or configuring module settings. The function also accepts optional parameters, enabling the implementation to fully comply with the requirements of a simple transfer.
   - **IOTA**: The init function in IOTA smart contracts is limited to two parameters: the one-time witness (otw) and the transaction context. This constraint prevents assigning a receiver address during contract deployment. To work around this, I designed a single-call function that can be executed once after deployment to securely define the receiver.
   - **Sui**: Like IOTA's initialization function, Sui's implementation faces a similar limitation, necessitating a purpose-built workaround to resolve this constraint.

2 Native token: 
