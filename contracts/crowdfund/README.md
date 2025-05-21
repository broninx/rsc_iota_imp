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

