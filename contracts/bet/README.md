# Bet

## Specification

The Bet contract involves two players and an oracle. The contract has the following parameters, defined at deployment time:
- **deadline**: a time limit (e.g. current block height plus a fixed constant); 
- **oracle**: the address of a user acting as an oracle.

After creation, the following actions are possible: 
- **join**: the two players join the contract by depositing their bets (the bets, that must be equal for both players, can be in the native cryptocurrency);
- **win**: after both players have joined, the oracle is expected to determine the winner, who receives the whole pot;
- **timeout** if the oracle does not choose the winner by the deadline, then both players can redeem their bets.

## Required functionalities

- Native tokens
- Multisig transactions
- Time constraints
- Transaction revert


## Implementation

### Introduction to IOTA

In IOTA, every address can hold balances of the native IOTA token (IOTA) and custom digital assets.

In IOTA, a foundational transaction type is the [user transaction](https://docs.iota.org/developer/iota-101/transactions/), which enables users to interact with smart contract and transfer assets, specially allow to send IOTA tokens (such as IOTA or MIOTA) between addresses. Each transaction specifies the sender’s address, the receiver’s address, and the amount of tokens being sent.Beyond basic value transfers, IOTA supports custom token transfers through its native tokenization framework.These transactions function allow users to create and send [custom assets](vhttps://docs.iota.org/developer/iota-101/create-coin/).

The fundamental unit of storage on IOTA is the object. Unlike many blockchains that focus on accounts containing key-value stores, IOTA's storage model centers around objects, each of which is addressable on-chain by a unique ID. In IOTA, a smart contract is an object known as a [package](https://docs.iota.org/references/framework/iota-framework/package), and these smart contracts interact with other objects on the IOTA network.

We will take a look at how a simple bet contract can be implemented in IOTA, using Move language.

### Logic Core

A package's utility is defined by its modules. A module contains the logic for your package. You can create any number of modules per package. In this case the module is colled bet.

```move
module bet::bet;
```

#### Initialization

In Move, the [init](https://docs.iota.org/developer/iota-101/move-overview/init) function plays a critical role during the module's lifecycle, executing only once at the moment of module publication.

```move
fun init (ctx: &mut TxContext){
      let oracle = Oracle {
        id: object::new(ctx),
        addr: ctx.sender(),
        deadline: 0
      };
      transfer::share_object(oracle);
  }
```
The function instantiates an oracle, which is subsequently shared across the chain via the [share_object](https://docs.iota.org/references/framework/testnet/iota-framework/transfer#function-share_object) function and get accessible the oracle instance for reads and writes by any transaction.

To set the deadline the Oracle can use the `initialize` function: 
 ```move
 public fun initialize(deadline: u64, oracle: &mut Oracle, ctx: &mut TxContext){
    assert!(ctx.sender() == oracle.addr, EPermissionDenied);
    oracle.deadline = deadline;
  }
```
#### Join

The `Join` function enables the participation of two users in a mutually agreed wager.

```move
public fun join<T> (
    clock: &Clock, 
    wager: coin::Coin<T>,
    p1: address, 
    p2: address, 
    oracle: &Oracle,
    ctx: &mut TxContext
    ){
        let wager = coin::into_balance(wager);
        let bet = Bet<T>{
          id: object::new(ctx),
          amount: wager,
          player1: p1,
          player2: p2,
          oracle: oracle.addr,
          timeout: timestamp_ms(clock) + oracle.deadline 
        };
        transfer::share_object(bet);
    }
```

To call the `join` function we require six parameters to be passed to the contract:

- **clock**: timestamp employed to record the initiation time of the wager;
- **wager**: a [coin](https://docs.iota.org/references/framework/iota-framework/coin) that enable participants to commit either the network’s native token or externally-defined fungible tokens;
- **p1 & p2**: two distinct addresses uniquely identify the counterparties involved in the wager;
- **oracle**: the oracle that decide the winner of the wager;
- **ctx**: [the transaction context](https://docs.iota.org/references/framework/testnet/iota-framework/tx_contex)

The function instantiates an bet, which is subsequently shared across the system via the [share_object](https://docs.iota.org/references/framework/testnet/iota-framework/transfer#function-share_object) function get accessible the bet instance for reads and writes by any transaction.

#### Win
After both players have joined the bet, the oracle is expected to determine the winner, calling the function `win`, who receives the whole pot.

```move
public fun win<T> (bet: Bet<T>, winner: address, clock: &Clock, ctx: &mut TxContext) {
    assert!(timestamp_ms(clock) < bet.timeout, EOverTimeLimit);
    assert!(winner == bet.player1 || winner == bet.player2, EWinnerNotPlayer);
    assert!(bet.oracle == ctx.sender(), EPermissionDenied);

    let Bet {id: id,amount: wager, player1: _, player2: _,oracle: _, timeout: _} = bet;
    let wager = coin::from_balance(wager, ctx);
    transfer::public_transfer(wager, winner);

    object::delete(id);
  }
```
To call the `win` function we require four parameters to be passed to the contract:

- **bet**: includes all bet information, including the participating players, oracle, start time, wagered amount, and timeout duration;
- **winner**: the address of the bet winner;
- **clock**: timestamp to verify whether the time has expired;
- **ctx**: [the transaction context](https://docs.iota.org/references/framework/testnet/iota-framework/tx_contex).

The function begins with three assertion checks:

- Validation that the winner determination timeframe has expired (via timestamp verification)
- Confirmation that the declared winner's address matches either of the two registered player addresses
- Authentication that the function caller holds the designated oracle role

Upon successful validation of all assertions, the function initiates the bet resolution process. This involves the [unpack](https://docs.iota.org/developer/iota-101/move-overview/structs-and-abilities/struct#Unpacking-a-Stuct) the bet instance to close it and the transfer of the entirety of the wager amount to the winner’s address via the [public_transfer](https://docs.iota.org/references/framework/testnet/iota-framework/transfer#function-public_transfer) function.

#### Timeout

```move
  public fun timeout<T> (bet: Bet<T>, clock: &Clock, ctx: &mut TxContext){
    assert!(clock.timestamp_ms() > bet.timeout, ETimeIsNotFinish);
    let Bet {id: id, amount:mut wager, player1: p1, player2: p2,oracle: _, timeout: _} = bet;
    object::delete(id);
    let amount = wager.value();

    let wager1 = wager.split(amount /2);
    
    transfer::public_transfer(coin::from_balance(wager, ctx), p1);
    transfer::public_transfer(coin::from_balance(wager1, ctx), p2);
  }
```
The timeout function is publicly accessible, meaning anyone can trigger it. When called, it first checks —via an initial `assert` statement— whether the predefined time limit has expired. Only if this condition is confirmed will the function execute, redistributing all funds exclusively back to the original parties.

To achieve this, we first [unpack](https://docs.iota.org/developer/iota-101/move-overview/structs-and-abilities/struct#Unpacking-a-Stuct) the bet instance to close it and then We split the original coin into two equal portions and use the [public_transfer](https://docs.iota.org/references/framework/testnet/iota-framework/transfer#function-public_transfer) function to return each half to its corresponding participant.


## Implementation differences

Below there are some of the most important differences in the bet implementation between Move diales like Aptos or SUI, and IOTA.

- **Aptos**: Use global ownership for all shared structs to enhance system security and employ local timestamps for deadline tracking

- **IOTA**: Use shared ownership for all shared structs to improve transaction parallelism, and rely on a global clock for deadline enforcement

- **SUI**: similar to IOTA’s design.

