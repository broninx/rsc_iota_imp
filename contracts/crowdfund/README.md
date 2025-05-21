# Crowdfund

## Specification

The Crowdfund contract allows users to donate native cryptocurrency to
fund a campaign.
To create the contract, one must specify:
- the *recipient* of the funds,
- the *goal* of the campaign, that is the least amount of currency that
must be donated in order for the campaign to be succesfull,
- the *deadline* for the donations.

After creation, the following actions are possible:
- **donate**: anyone can transfer native cryptocurrency to the contract
until the deadline;
- **withdraw**: after the deadline, the recipient can withdraw the funds
stored in the contract, provided that the goal has been reached;
- **reclaim**: after the deadline, if the goal has not been reached
donors can withdraw the amounts they have donated.

## Required functionalities

- Native tokens
- Time constraints
- Transaction revert
- Key-value maps

## Implementation

### Donate

```move
public fun donate(donation: Coin<IOTA>, crowdfund: &mut Crowdfund, clock: &Clock, ctx: &mut TxContext){
    assert!(clock.timestamp_ms() <= crowdfund.deadline, ETimeFinished);
    assert!(crowdfund.initialized, ENotInitialized);

    crowdfund.amount = crowdfund.amount + donation.value();
    if (crowdfund.donors.contains(&ctx.sender())){
        let donation_just_sended = crowdfund.donors.get_mut(&ctx.sender());
        donation_just_sended.join(donation);
    } else {
        crowdfund.donors.insert(ctx.sender(), donation);
    };
}
```

The Crowdfund struct uses a [map](https://docs.iota.org/references/framework/testnet/iota-framework/vec_map) to track donations, where each donor serves as a key and their cumulative donation total acts as the corresponding value. When a donor makes multiple contributions, the amounts are automatically aggregated into their existing total within the map.

### Withdraw

```move
public fun withdraw(mut crowdfund: Crowdfund, clock: &Clock, ctx: &mut TxContext){
    assert!(crowdfund.recipient == ctx.sender(), EPermissionDenied);
    assert!(clock.timestamp_ms() >= crowdfund.deadline, ETimeNotFinished);
    assert!(crowdfund.amount >= crowdfund.goal, EGoalNotAchived);

    let mut donations = coin::zero<IOTA>(ctx);
    while (!crowdfund.donors.is_empty()) {
        let (_, donation) = crowdfund.donors.pop();
        donations.join(donation);
    };
    iota::transfer(donation, crowdfund.recipient);
    crowdfund.destroy();
}
```

Once the donation period ends and the funding goal is met, the beneficiary can claim the total raised funds. This is achieved by summing all contributions from the hash map and transferring the aggregated amount to the beneficiary's address.

### Reclaim

```move
public fun reclaim(mut crowdfund: Crowdfund, clock: &Clock, ctx: &mut TxContext){
    assert!(clock.timestamp_ms() >= crowdfund.deadline, ETimeNotFinished);
    assert!(crowdfund.amount < crowdfund.goal, EGoalAchived);
    assert!(crowdfund.donors.contains(&ctx.sender()), ENotDonor);

    let (donor, donation) = crowdfund.donors.remove(&ctx.sender());
    iota::transfer(donation, donor);
    if (crowdfund.donors.is_empty()){
        crowdfund.destroy();
    } else {
        transfer::share_object(crowdfund);
    }
}
```

If the funding `goal` is not met by the campaign `deadline`, donors may manually invoke the `reclaim` function. The contract checks if the caller exists in the hash map: if present, their pledged amount is transferred back and their [entry](https://docs.iota.org/references/framework/testnet/iota-framework/vec_map#0x2_vec_map_Entry) is removed. If the donor has no pledged amount (or already reclaimed), an assertion fails, reverting the transaction. Once all donors have reclaimed their funds and the hash map is empty, the Crowdfund contract self-destructs.


### Implemetation differences

TODO
