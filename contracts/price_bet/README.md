# Price Bet

## Specification

The PriceBet contract allows anyone to bet on a future exchange rate between two tokens. 
Its specification is adapted from the [Clockwork Finance](https://arxiv.org/abs/2109.04347) paper.

The contract has the following parameters, defined at deployment time: 
- an **owner**, who deposits the initial pot (in the native cryptocurrency);
- an **oracle**, a contract that is queried for the exchange rate between two given tokens;
- a **deadline**, a time limit after which the player loses the bet (e.g. the current block height plus a fixed constant); 
- an **exchange rate**, that must be reached in order for the player to win the bet.  
 
After creation, the following actions are possible: 
- **join**: a player joins the contract by depositing an amount of native cryptocurrency equal to the initial pot;
- **win**: after the join and before the deadline, the player can withdraw the whole pot if the oracle exchange rate is greater than the bet rate;
- **timeout**: after the deadline, the owner can redeem the whole pot.

## Required functionalities

- Native tokens
- Time constraints
- Transaction revert
- Contract-to-contract calls

## Implementation

Our solution employs two distinct Sui Move modules to fulfill the contract requirements. The Oracle Module exclusively handles the creation and management of oracle objects, where each oracle instance stores a specific exchange rate value. Separately, the PriceBet Module contains all betting logic and state management. When a player initiates a win action after joining a bet, the function requires a direct reference to an oracle object. Critical security verification occurs through address matching: the oracle reference provided must correspond exactly to the oracle address stored in the PriceBet instance. Only after confirming this identity match does the contract compare the oracle's current exchange rate against the predetermined target rate to determine if the player wins.

```move
public fun win(oracle: &Oracle, mut price_bet: PriceBet, clock: &Clock, ctx: &mut TxContext){
    assert!(price_bet.state == ONGOING, EWrongState);
    assert!(price_bet.oracle == oracle.addr(), EWrongOracle);
    assert!(price_bet.deadline >= clock.timestamp_ms(), EWrongTime);
    assert!(oracle.exchange_rate() > price_bet.exchange_rate, ENotWin);
    let value = price_bet.pot.value();
    let coin = coin::take(&mut price_bet.pot, value, ctx);
    let recipient = price_bet.player;
    price_bet.destroy();
    transfer::public_transfer(coin, recipient);
}
```

## Differences

The Price Bet implementation retains the same discrepancies with other diales identified in the previous implementations.
