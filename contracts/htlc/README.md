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
    hash: vector<u8>, 
    timeout: u64, 
    coin: Coin<IOTA>,
    htlc: Htlc,
    clock: &Clock, 
    ctx: &mut TxContext){
    assert!(ctx.sender() == htlc.owner, EPermissionDenied);
    assert!(!htlc.initialized, EJustInitialized);

    let Htlc {
        id: id, 
        owner: owner,
        receiver: _,
        hash: _,
        reveal_timeout: _,
        coin: mut htlc_coin,
        initialized: _
    } = htlc;

    let htlc_coin.join(coin);
    let htlc = Htlc {
        id: object::new(ctx),
        owner: owner,
        receiver: receiver,
        hash: hash,
        reveal_timeout: clock::timestamp_ms(clock) + timeout,
        coin: htlc_coin,
        initialized: true
    };
    object::delete(id);
    transfer::share_object(htlc);
}
```

