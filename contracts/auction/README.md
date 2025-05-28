# Auction

## Specification

The contract allows a seller to create an english auction, with bids in the native cryptocurrency.

The seller creates the contract by specifying:
- the starting bid of the auction;
- the duration of the auction (i.e., the period of time in which bids are open from the start of the auction);
- the object of the auction (a string, used for notarization purposes only).

After creation, the contract supports the following actions:
- **start**, which allows the seller to start the auction. 
- **bid**, which allows any user to bid any amount of native cryptocurrency after the auction has started and before its duration has expired. If the the amount of the bid is greater than the current highest bid, then it is transferred to the contract; otherwise, it is returned back to the user.
- **withdraw**, which allows any user, at any time, to withdraw their bid if this is not the currently highest one.
- **end**, which allows the seller to end the auction after its duration has expired, and to withdraw the highest bid.

## Required functionalities

- Native tokens
- Time constraints
- Transaction revert
- Key-value maps

## Implementation

In each use case, we begin by initializing the function, then move on to explaining the start function directly.

### Start

```move
public fun start(auction: &mut Auction, clock: &Clock, ctx: &mut TxContext){
    assert!(auction.state == ACTIVE, EPermissionDenied);
    assert!(auction.seller == ctx.sender(), EPermissionDenied);
    auction.deadline = auction.deadline + clock::timestamp_ms(clock);
    auction.state = ONGOING;
}
```
The `start` function initiates the auction's bidding period. This function can only be called by the seller, transitioning the auction state from `ACTIVE` to `ONGOING`.

### Bid

```move

public fun bid(bid: Coin<IOTA>, auction: &mut Auction, clock:&Clock, ctx: &mut TxContext){
    assert!(auction.deadline >= clock.timestamp_ms(), ETimeFinished);
    assert!(bid.value() > auction.top_bid.value(), EBidTooMuchLower);
    assert!(auction.state == ONGOING, EPermissionDenied);

    let low_bid = coin::take(auction.top_bid, auction.top_bid.value(), ctx);
    transfer::public_transfer(low_bid, auction.bidder);

    let top_bid = coin::into_balance(bid);
    auction.top_bid.join(top_bid);
    auction.bidder = ctx.sender();
}
```

Bidding is the mechanism through which users participate in the auction. To maintain the highest bid, each new offer must exceed the current highest amount. Once the bidding period ends, no further bids are permitted.

Bids are submitted using IOTA native tokens (coins), while the highest bid is tracked as a balance stored within the auction struct. When a new bid is placed, the system verifies whether its value exceeds the current highest bid. If valid, the incoming coin is converted into a balance and set as the new `top_bid` in the auction. Simultaneously, the previous highest bid’s balance is refunded to the original `bidder`, whose address is retained in the auction’s bidder field.

A dedicated withdraw function is functionally unnecessary, as outbid bids are automatically refunded to their respective bidders in real-time.

### End

```move
public fun end(auction: Auction,clock: &Clock, ctx: &mut TxContext){
    assert!(auction.seller == ctx.sender(), EPermissionDenied);
    assert!(clock.timestamp_ms()> auction.deadline, ETimeNotFinished);
    assert!(auction.state == ONGOING, EPermissionDenied);
    let Auction {
        id: uid,
        seller: seller,
        bidder: _,
        thing: _,
        top_bid: bid_balance,
        deadline: _,
        state:_ 
    } = auction;
    object::delete(uid);
    let bid_coin = coin::from_balance(bid_balance, ctx);
    transfer::public_transfer(bid_coin, seller);
}
```

When the auction concludes, the on-chain auction instance is decommissioned. The highest bid’s balance (stored in the auction struct) is converted into IOTA coins and transferred to the seller. If no bids were placed during the auction, the initial offering (e.g., the seller’s starting bid) is returned to them.

## Implementation differences

The Auction implementation retains the same discrepancies with other diales identified in the previous implementations.
