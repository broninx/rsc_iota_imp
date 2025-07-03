# Simple transfer

## Specification 

The contract allows a user (the *owner*) to deposit native cryptocurrency, 
and another user (the *recipient*) to withdraw arbitrary fractions of the contract balance.

At contract creation, the owner specifies the receiver's address.

After contract creation, the contract supports two actions:
- **deposit** allows the owner to deposit an arbitrary amount of native cryptocurrency in the contract;
- **withdraw** allows the receiver to withdraw any amount of the cryptocurrency depositd in the contract.

## Required functionalities

- Native tokens
- Transaction revert

## Implementation

### Initialization

```move
public fun initialize(receiver: address, ctx: &mut TxContext){
    let wallet = Wallet {
        id: object::new(ctx),
        balance: balance::zero<IOTA>(),
        owner: ctx.sender(),
        receiver: receiver,
    };
    transfer::share_object(wallet);
}
```
The initialize function configures a new wallet by storing the provided receiver address as a parameter and designating the transaction sender as the owner. The wallet's initial balance is set using the zero function from the Balance module, which instantiates a zero-value Balance<T> object. Following this initialization, the function finalizes the process by publishing the wallet struct to the blockchain. In this context, the generic type T is specialized as IOTA – the native asset denomination of the IOTA network. Represented by the type 0x2::iota::IOTA, this asset is fundamental for covering transaction gas fees, enabling data persistence on-chain, and facilitating network operations. All base-layer IOTA tokens exist as instances of this type.

### Deposit

```move
public fun deposit(amount: Coin<IOTA>,wallet:&mut Wallet, ctx: &mut TxContext){
    assert!(ctx.sender() == wallet.owner, EPermissionsDenied);
    
    let balance_to_deposit = coin::into_balance<IOTA>(amount);
    wallet.balance.join(balance_to_deposit);
}
```

The deposit function enables the wallet owner to transfer [IOTA](https://docs.iota.org/developer/stardust/units#iota) (the network's native token) into the Wallet. This operation is restricted to the owner, enforced by an initial ownership verification assert in the function’s logic. Upon successful validation, the specified IOTA amount is securely added to the Wallet’s balance.

IOTA coins are wrapped in a [Coin](https://docs.iota.org/references/framework/iota-framework/coin#0x2_coin_Coin) type, which acts as a container for balances. To extract the underlying value, the into_balance function from the [coin module](https://docs.iota.org/references/framework/iota-framework/coin) is invoked, converting the Coin into a balance.
The converted balance (provided by the owner) is then added to the Wallet’s total balance, finalizing the deposit.

### Withdraw

```move
public fun withdraw(amount: u64, wallet: &mut Wallet, ctx: &mut TxContext){
    assert!(ctx.sender() == wallet.receiver, EPermissionsDenied);
    assert!(amount <= wallet.balance.value(), EBiggerThanBalance);

    let withdraw_balance = wallet.balance.split(amount);
    let withdraw_coin = coin::from_balance(withdraw_balance, ctx);
    iota::transfer(withdraw_coin, ctx.sender());
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

Init: the init function is a special one-time initialization function that automatically executes during the deployment of a module.
   - **Aptos**: it accepts a &signer parameter (representing the deployer’s address) and is used to set up initial on-chain state, such as creating global resources or configuring module settings. The function also accepts optional parameters, enabling the implementation to fully comply with the requirements of a simple transfer.
   - **IOTA**: The init function in IOTA smart contracts is limited to two parameters: the one-time witness (otw) and the transaction context. This constraint prevents assigning a receiver address during contract deployment. To work around this, I designed a single-call function that can be executed once after deployment to securely define the receiver.
   - **SUI**: Like IOTA's initialization function, Sui's implementation faces a similar limitation, necessitating a purpose-built workaround to resolve this constraint.

Native token:
- **Aptos**: In Aptos, native tokens ollows the generic standard but is privileged (e.g., only APT can be used for gas).
- **IOTA**: The IOTA token is the lifeblood of the network, enabling feeless transactions, consensus via mana, and protocol-level security.
- **SUI**: Sui Move shares similarities with Aptos Move in how they manage native tokens.
