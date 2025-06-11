# Lottery

## Specification

Consider a lottery where two players bet an equal amount of crypto-currency, and the winner - who is chosen fairly between the two players - redeems the whole pot.

Since smart contract are deterministic and external sources of randomness (e.g., random number oracles) might be biased, to achieve fairness we follow a *commit-reveal-punish* protocol, where both players first commit to the hash of the secret, then reveal their secret (which must be a preimage of the committed hash), and finally the winner is computed as a fair function of the secrets.

Implementing this protocol properly is quite error-prone, since the protocol must punish players who behave dishonestly, e.g. by refusing to perform some required action. In this case, the protocol must still ensure that, on average, an honest player has at least the same payoff that she would have by interacting with another honest player. 

The protocol followed by (honest) players is the following:
1. `player1` and `player2` join the lottery by paying the bet and committing to a secret (the bet is the same for each player);
2. `player1` reveals the first secret;
3. if `player1` has not revealed, `player2` can redeem both players' bets after a given deadline (`end_reveal`); 
4. once `player1` has revealed, `player2` reveals the secret;
5. if `player2` has not revealed, `player1` can redeem both players' bets after a given deadline (`end_reveal` plus a fixed constant);
6. once both secrets have been revealed, the winner, who is fairly determined as a function of the two revealed secrets, can redeem the whole pot.

If the platform does not support multisig transactions, then step 1 is split in the following sub-steps: 
- `player1` joins the lottery by paying the bet and committing to a secret;
- `player2` joins the lottery by paying the bet and committing to another secret;
- if `player2` has not joined, `player1` can redeem her bet after a given deadline (`end_commit`).

## Required functionalities

- Native tokens
- Multisig transactions
- Time constraints
- Transaction revert
- Hash on arbitrary messages
- Bitstring operations
- **Randomness**

## Implementation 

```move
public fun join1<T>(deadline_commit: u64, coin: Coin<T>, hash: vector<u8>, clock: &Clock, ctx: &mut TxContext){
    let lottery = Lottery{
        id: object::new(ctx),
        player1: ctx.sender(),
        player2: @0x0,
        hash1: hash,
        hash2: b"",
        end_commit: (deadline_commit * 60000) + clock.timestamp_ms(),
        end_reveal1: 0,
        end_reveal2: 0,
        balance: coin.into_balance(),
        state: JOIN1
    };
    transfer::share_object(lottery);
}
```

The lottery participation process requires a two-step design. First, the join function initializes the lottery by creating a Lottery struct, recording the sender's address in the player1 field. Simultaneously, it calculates a commitment deadline (end_commit) by taking the current timestamp and adding a 10-minute window. If any subsequent caller triggers the join2 function before this end_commit expiration, the original player (player1) gains the ability to invoke redeem_commit. This function allows player1 to reclaim their staked funds and permanently deletes the lottery entry, ensuring recovery when the second participant fails to join within the allotted timeframe.

```move
public fun redeem_commit<T>(clock: &Clock, lottery: Lottery<T>, ctx: &mut TxContext){
    assert!(lottery.state == JOIN1, EWrongState);
    assert!(lottery.end_commit < clock.timestamp_ms(), ETimeNotExpired);
    assert!(lottery.player1 == ctx.sender(), EPermissionDenied);

    let player1 = lottery.player1;
    let balance = lottery.destroy();
    transfer::public_transfer(coin::from_balance(balance, ctx), player1);

}
```
