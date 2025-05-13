# Token transfer

## Specification 

The contract TokenTransfer allows a user (the *owner*)
to transfer units of a token (possibly, not the native cryptocurrency) to the contract, 
and another user (the *recipient*) to withdraw.

At contract creation, the owner specifies the receiver's address and the token address.

After contract creation, the contract supports two actions:
- **deposit**, which allows the owner to deposit an arbitrary amount of tokens
in the contract;
- **withdraw**, which allows the receiver to withdraw 
any amount of the token deposited in the contract.

## Required functionalities
- Custom tokens
- Transaction revert
  
## Implementation

The token transfer implementation shares the core structure of [simple transfer](https://github.com/broninx/rsc_iota_imp/tree/main/contracts/simple_transfer) but introduces a critical enhancement: a generic type system that extends support to any token type rather than being restricted to IOTA. This modification requires the sender to specify both the recipient address and the token type, which is why the function evolved from set_receiver to set_balance_and_receiver.

### set_balance_and_receiver

```move
public fun set_balance_and_receiver<T>(receiver: address,wallet: Wallet<IOTA>, ctx: &mut TxContext){
    assert!(!wallet.initialized, EPermissionsDenied);
    assert!(ctx.sender() == wallet.owner, EPermissionsDenied);
    let Wallet<IOTA> {id: uid, balance: balance, owner: owner, receiver: _, initialized: _} = wallet; 
    let wallet = Wallet<T>{
        id: object::new(ctx),
        balance: balance::zero<T>(),
        owner: owner,
        receiver: receiver,
        initialized: true
    };
    balance.destroy_zero();
    object::delete(uid);
    transfer::share_object(wallet);
}
```

The set_balance_and_receiver function accepts three inputs:
1. The recipient’s address
2. The wallet instance shared in the smart contract
3. The transaction context

First, it verifies that the `initialized` flag is set to `true` and confirms the transaction sender is the authorized owner of the wallet. If both checks succeed, the function decommissions the original wallet (created during contract deployment) and dynamically generates a replacement wallet. This new wallet retains the original owner but updates the `balance` to reflect the token type specified in the function call, assigns the provided `receiver` address, and resets the `initialized` flag to true. Finally, the system destroys the IOTA token balance and the unique identifier ([UID](https://docs.iota.org/developer/iota-101/objects/uid-id)) of the old wallet and publishes the updated wallet to the contract.

## Implementation differences

In their initialization functions, Aptos, IOTA, and SUI exhibit differences analogous to [simple transfer](https://github.com/broninx/rsc_iota_imp/tree/main/contracts/simple_transfer) logic. Additionally, IOTA restricts the contract owner from setting the token balance during deployment, requiring adjustments post-creation instead, a limitation tied to its architectural design, similar to the problem with the "receiver" in simple transfer. SUI follows a pattern comparable to IOTA in this regard. In contrast, Aptos aligns seamlessly with specifications, enabling direct configuration of token balances at deployment time without requiring post-creation modifications. 

Custom tokens:
- **Aptos**: Generic tokens are flexible, user-defined assets built on Move’s resource model, leveraging Aptos’ security but operating at the application layer. Like native token, generic tokens are menaged with the [coin standard](https://github.com/aptos-labs/aptos-core/blob/main/aptos-move/framework/aptos-framework/sources/coin.move).
- **IOTA**: Generic tokens are application-specific assets built on top of IOTA, leveraging its infrastructure but operating through higher-layer modules without affecting core network mechanics.
In the IOTA framework, custom tokens and native tokens are managed in two distinct modules: the [coin module](https://docs.iota.org/references/framework/iota-framework/coin) handles custom tokens, while the [iota module](https://docs.iota.org/references/framework/testnet/iota-framework/iota) is responsible for native tokens.
- **SUI**:  Sui shares similarities with Aptos in how they manage generic tokens, but key differences arise from Sui’s object-centric model and unique programming paradigm. Also in SUI, like native token, generic tokens are menaged with the [coin module](https://docs.sui.io/references/framework/sui/coin).
