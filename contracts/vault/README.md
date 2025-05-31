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

### Initialization

```move
fun init(ctx: &mut TxContext){
    let owner = Owner {
        id: object::new(ctx),
        addr: ctx.sender()
      };
    transfer::share_object(owner);
}
```

This use case implements an alternative contract initialization method. A struct Owner stores the contract owner's address. During deployment:
1. An Owner instance is created,
2. The deployer's (sender's) address is saved as the owner
3. The Owner instance is persisted on-chain

Subsequently, only this owner may call the initialize function.

```move
public fun initialize<T>(recovery_key: vector<u8>, wait_time: u64, owner: Owner, ctx: &mut TxContext){
    assert!(ctx.sender() == owner.addr, EPermissionDenied);
    let Owner {id: id, addr: owner} = owner;
    let vault = Vault<T> {
        id: object::new(ctx),
        owner: owner,
        receiver: @0x0,
        amount: balance::zero<T>(),
        withdrawal_amount: 0,
        recovery_key: recovery_key,
        wait_time: wait_time * 1000,
        deadline: 0,
        state: READY
    };
    id.delete();
    transfer::share_object(vault);
}
```
The `initialize` function accepts all required configuration parameters - including `recovery_key`, `wait_time`, and `owner`. Within this function, the `owner` parameter is intentionally destroyed (consumed) after its address is stored in a new Vault struct instance. This vault structure, now containing all validated configuration parameters, is subsequently shared on-chain. This is design ensures only a single vault instance can ever be created.

## Differeces

### Dialect differences

The Vault implementation retains the same discrepancies with other diales identified in the previous implementations.

### Implementation differences

differences between aptos, sui and iota: 
- **Aptos**: coherent with specifications
- **IOTA**:  coherent with specifications
- **Sui**:No explicit deposit; `finalize` withdraws coins to a provided coin object. No explicit receiver field.
