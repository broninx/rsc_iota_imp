# Vault

## Specification

Vaults are a security mechanism to prevent cryptocurrency from being immediately withdrawn by an adversary who has stolen the owner's private key.

To create the vault, the owner specifies: 
- a recovery key, which can be used to cancel a withdraw request;
- a wait time, which has to elapse between a withdraw request and the actual finalization of the cryptocurrency transfer.

Once the vault contract have been created, it supports the following actions:
- **receive**, which allows anyone to deposit native cryptocurrency in the contract;
- **withdraw**, which allows the owner to issue a withdraw request to the vault, specifying the receiver and the desired amount;
- **finalize**, which allows the owner to finalize the withdraw after the wait time has passed since the request; 
- **cancel**, which allows the owner of the recovery key to cancel the withdraw request during the wait time.

## Required functionalities

- Native tokens
- Time constraints
- Transaction revert

## Implementation

### Initialize

```move
public fun initialize<T>(recovery_key: vector<u8>, wait_time: u64, vault: Vault<IOTA>, ctx: &mut TxContext){
    assert!(vault.state == INIT, EPermissionDenied);
    assert!(ctx.sender() == vault.owner, EPermissionDenied);
    let Vault {
        id: id,
        owner: owner,
        receiver: receiver,
        amount: old_balance,
        withdrawal_amount: _,
        recovery_key: _,
        wait_time: _,
        deadline: _,
        state: _
    } = vault;
    old_balance.destroy_zero();
    object::delete(id);
    let vault = Vault<T> {
        id: object::new(ctx),
        owner: owner,
        receiver: receiver,
        amount: balance::zero<T>(),
        withdrawal_amount: 0,
        recovery_key: recovery_key,
        wait_time: wait_time * 1000,
        deadline: 0,
        state: READY
    };
    transfer::share_object(vault);
}
```
In Move's type system, `Vault<IOTA>` and `Vault<T>` are fundamentally distinct types, making it impossible to modify an existing object's generic type parameter in-place. This design preserves Move's strict type safety guarantees and maintains object identity integrity within IOTA's framework. To transition between token types, the original `Vault<IOTA>` must be fully unpacked and destroyed, after which a new `Vault<T>` instance is created with a fresh object ID. This recreation process allows for the desired token type transition while preserving non-generic fields like `owner` and `receiver`, and simultaneously enables the configuration of new parameters such as `recovery_keys` and `wait_time`. The destruction-and-recreation pattern ensures that all type-dependent state (particularly token balances) is properly reinitialized under the new type regime, maintaining the language's security invariants while enabling flexible token system design.

## Differeces

### Dialect differences

The Vault implementation retains the same discrepancies with other diales identified in the previous implementations.

### Implementation differences

differences between aptos, sui and iota: 
- **Aptos**: coherent with specifications
- **IOTA**:  coherent with specifications
- **Sui**:No explicit deposit; `finalize` withdraws coins to a provided coin object. No explicit receiver field.
