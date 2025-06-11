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

### Join1 and Redeem_commit
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

The lottery participation process requires a two-step design. First, the `join` function initializes the lottery by creating a `Lottery` struct, recording the sender's address in the `player1` field and the submitted hash phrase in `hash1`. Simultaneously, it calculates a commitment deadline (`end_commit`) by taking the current timestamp and adding a 10-minute window. If any subsequent caller triggers the `join2` function before this `end_commit` expiration, the original `player` gains the ability to invoke `redeem_commit`. This function allows `player1` to reclaim their staked funds and permanently deletes the lottery entry, ensuring recovery when the second participant fails to join within the allotted timeframe.

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

### Join2

```move
public fun join2<T>(coin: Coin<T>, hash: vector<u8>, clock: &Clock, lottery: &mut Lottery<T>, ctx: &mut TxContext){
    assert!(lottery.state == JOIN1, EWrongState);
    assert!(lottery.end_commit >= clock.timestamp_ms(), ETimeExpired);
    assert!(lottery.balance.value() == coin.value(), EWrongAmount);

    lottery.player2 = ctx.sender();
    lottery.balance.join(coin.into_balance());
    lottery.hash2 = hash;
    lottery.end_reveal1 = 600000 + clock.timestamp_ms();
    lottery.state = JOIN2;
}
```

The join2 function performs these sequential checks:
1. Verifies the lottery is in pending status
2. Confirms the commit phase has not expired
3. Ensures the sent wager matches the initial bet amount

If all checks pass, the function:
- Registers the sender as `player2`
- Stores the submitted hash phrase in `hash2`
- Sets the end_reveal deadline to 10 minutes after the current timestamp

### Reveal

The reveal phase is implemented through two functions: `reveal1` and `reveal2`. Both functions perform identical validation steps but for their respective players:
- `reveal1` verifies the sender is `player1` and that their submitted `secret` produces (via keccak256 hashing) the previously stored `hash1`
- `reveal2` verifies the sender is `player2` and that their submitted `secret` produces the stored `hash2`

Additionally, `reveal1` establishes a reveal deadline for `player2` when successfully executed.

```move
public fun reveal1<T>(secret: vector<u8>, clock: &Clock, lottery: &mut Lottery<T>, ctx: &mut TxContext){
    assert!(lottery.state == JOIN2, EWrongState);
    assert!(lottery.player1 == ctx.sender(), EPermissionDenied);
    assert!(lottery.end_reveal1 >= clock.timestamp_ms(), ETimeExpired);
    assert!(keccak256(&secret) == lottery.hash1, EWrongSecret);
    lottery.hash1 = secret;
    lottery.state = REVEAL1;
    lottery.end_reveal2 = 600000 + clock.timestamp_ms();
}

public fun reveal2<T>(secret: vector<u8>, clock: &Clock, lottery: &mut Lottery<T>, ctx: &mut TxContext){
    assert!(lottery.state == REVEAL1, EWrongState);
    assert!(lottery.player2 == ctx.sender(), EPermissionDenied);
    assert!(lottery.end_reveal2 >= clock.timestamp_ms(), ETimeExpired);
    assert!(keccak256(&secret) == lottery.hash2, EWrongSecret);
    lottery.hash2 = secret;
    lottery.state = REVEAL2;
}
```

### Redeem

The redeem function enables honest players to recover funds when opponents miss reveal deadlines:
- Player2 may call it after `end_reveal1` expires (if Player1 failed to reveal)
- Player1 may call it after `end_reveal2` expires (if Player2 failed to reveal)

```move
public fun redeem<T>(clock: &Clock, lottery: Lottery<T>, ctx: &mut TxContext){
    let time_expired2 = lottery.state == REVEAL1 && ctx.sender() == lottery.player1 && clock.timestamp_ms() > lottery.end_reveal2;
    let time_expired1 = lottery.state == JOIN2 && ctx.sender() == lottery.player2 && clock.timestamp_ms() > lottery.end_reveal1;
    assert!(time_expired2 || time_expired1, ETimeNotExpired);
    let recipient: address;
    if (time_expired2){
        recipient = lottery.player1;
    } else {
        recipient = lottery.player2;
    };
    let balance = lottery.destroy(); 
    transfer::public_transfer( coin::from_balance(balance, ctx), recipient);
}
```

Upon successful execution, the function returns the entire contract balance to the caller, permanently destroys the lottery instance. Redeem serves as a penalty mechanism against dishonest participants who neglect to reveal their commitments.

### Win 

```move
public fun win<T>(lottery: Lottery<T>, ctx: &mut TxContext){
    assert!(lottery.state == REVEAL2, EWrongState);
    let winner: address;
    if ((lottery.hash1.length() + lottery.hash2.length()) % 2 == 0){
        winner = lottery.player1;
    } else {
        winner = lottery.player2;
    };
    let balance = lottery.destroy();
    transfer::public_transfer(coin::from_balance(balance, ctx), winner);
}
```

The win function serves as the final resolution mechanism once both players have successfully completed the reveal phase. This publicly callable function calculates the combined character length of both players' revealed secrets. Using this total length as a deterministic arbiter, it transfers the entire contract balance to player1 if the sum is even, or to player2 if the sum is odd. This cryptographic length-check provides a trustless, verifiable method to distribute winnings without relying on external randomness or subjective judgment, while ensuring the lottery contract can be securely concluded after execution.

## Differences

The Lottery implementation retains the same discrepancies with other diales identified in the previous implementations.
