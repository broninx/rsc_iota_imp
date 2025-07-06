# Vesting

## Specification

The contract handles the maturation (vesting) of native cryptocurrency for a given beneficiary. 

The contract is initialized by setting: 
- the address of the beneficiary,
- the first block height (start) where the beneficiary can withdraw funds,
- the overall duration of the vesting scheme,
- the initial balance, in native cryptocurrency.
 
After creation, the contract supports the following action:
- **release**, which allows the beneficiary to withdraw part of the vested amount, according to the following policy:
  - before the start block, the amount is zero;
  - at any moment between the start and the expiration of the vesting scheme, the amount is proportional to the time passed since the start of the scheme; 
  - once the scheme is expired, the amount is the entire contract balance. 

## Required functionalities

- Native tokens
- Time constraints
- Transaction revert

## Implementation

The init and initialize functions followed the same implementation patterns, with no distinct differences with other implementations.

### Release

```move
public fun release(vesting: &mut Vesting, clock: &Clock, ctx: &mut TxContext){
    assert!(vesting.beneficiary == ctx.sender(), EPermissionDenied);

    let clamped_time = max(vesting.start, min(vesting.end, clock.timestamp_ms()));
    let amount = vesting.balance.value() * (clamped_time - vesting.start)/ (vesting.end - vesting.start);
    let coin = coin::take(&mut vesting.balance, amount, ctx);
    transfer::public_transfer(coin, vesting.beneficiary);
}
```

The `release` function dynamically calculates distributable tokens based on the vesting schedule and the caller’s interaction history. If invoked before the vesting period begins, the `beneficiary` receives 0 tokens, as no time has accrued. During the vesting window, the released amount is proportional to the time elapsed between `start` and `end`, calculated against the current remaining balance (the original total minus previously claimed amounts). The beneficiary can call the function repeatedly during this phase to claim incremental portions, with each claim reducing the remaining balance.

## Implementation Differences

The Vesting implementation retains the same discrepancies with other diales identified in the previous implementations.
