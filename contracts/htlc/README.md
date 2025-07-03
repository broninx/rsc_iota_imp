# HTLC

## Specification

The Hash Timed Locked Contract (HTLC) involves two users, the *committer* and the *receiver*.

At contract creation, the committer:
- deposits a collateral (in native cryptocurrency) in the contract;
- specifies a deadline for the secret revelation, in terms of a delay from the publication of the contract;
- specifies the receiver of the collateral, in case the deposit is not revealed within the deadline.
- commits to a value, that is the Keccak-256 digest of a secret bitstring chosen by the committer.

After contract creation, the contract supports two actions:
- **reveal**, which allows the committer to redeem the whole contract balance by providing a preimage of the committed hash;
- **timeout**, which can be called only after the deadline, and tranfers the whole contract balance to the receiver.

## Required functionalities

- Native tokens
- Time constraints
- Transaction revert
- Hash on arbitrary messages

## Implementation

### Initialization

After deploying the contract, the owner must call the initialize function to configure the contract with all required parameters.

```move
public fun initialize(
    receiver: address,
    preimage: vector<u8>, 
    timeout: u64, 
    coin: Coin<IOTA>,
    clock: &Clock, 
    ctx: &mut TxContext){
    let htlc = Htlc {
        id: object::new(ctx),
        committer: ctx.sender(),
        receiver: receiver,
        hash: hash::keccak256(&preimage),
        deadline: clock::timestamp_ms(clock) + timeout,
        amount: coin::into_balance(coin),
    };
    transfer::share_object(htlc);
}
```

The committer must provide the following parameters during initialization via the `initialize` function:
- **Receiver Address**: Designated to receive funds in the event of a timeout.
- **Native Cryptocurrency Amount**: The locked value (e.g., in IOTA).
- **Timeout Duration**: A predefined period (in milliseconds) before the contract expires.
- **hash phrase**: A secret bitstring (that will be automatically changed with his respective keccak-256 digest by the [keccak256 function](https://docs.iota.org/references/framework/testnet/iota-framework/hash#function-keccak256))


The initialize function instantiates an HTLC struct, mapping supplied parameters to their respective struct fields. Crucially, the preimage is stored as its Keccak-256 digest (computed via the hash module's keccak256 function). The initialize function automatically records the current timestamp (in milliseconds) and combines this with the deadline parameter to compute the final deadline. The initialized struct is then persisted on-chain.

### Reveal

The reveal function requires three inputs: a secret, a string value (in Move, strings are represented as vector<u8>); Htcl, a struct containing the contract’s state data (receiver, amount, deadline, ecc...); ctx, the trasaction context.

```move
public fun reveal(secret: vector<u8>, htlc: Htlc, ctx: &mut TxContext){
    assert!(ctx.sender() == htlc.committer, EPermissionDenied);
    assert!(htlc.hash == hash::keccak256(&secret), EWrongSecret);

    let Htlc {
        id: id,
        committer: committer,
        receiver: _,
        hash: _,
        deadline: _,
        amount: coin,
        initialized: _
    } = htlc;
    object::delete(id);
    iota::transfer(coin, committer);
}
```

During the `reveal` function’s execution, the system first validates whether the Keccak-256 hash of the provided `secret` matches the pre-stored `hash` within the Htcl struct. If verified, the committer redeems the locked collateral, and the Htcl struct is permanently removed from storage, terminating the contract’s lifecycle.

### Timeout

The `timeout` function validates whether the current timestamp exceeds the predefined deadline. If true, it deallocates the Htcl struct and transfers the entire locked `amount` to the designated `receiver`, terminating the contract's lifecycle.

```move
public fun timeout(clock: &Clock, htlc: Htlc){
    assert!(clock::timestamp_ms(clock) > htlc.deadline, ETimeNotFinished);
    let Htlc {
        id: id,
        committer: _,
        receiver: receiver,
        hash: _,
        deadline: _,
        amount: coin,
        initialized: _
    } = htlc;

    object::delete(id);
    iota::transfer(coin, receiver);

}
```

## Implementation differences

The HTCL implementation retains the same discrepancies with other diales identified in the previous implementations.
