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

IOTA, a pioneering distributed ledger technology (DLT), diverges from traditional blockchains by utilizing the Tangle, a Directed Acyclic Graph (DAG) structure. This innovation eliminates blocks, chains, and miners, enabling feeless transactions, scalability, and energy efficiency. While initially focused on the Internet of Things (IoT), IOTA has expanded its capabilities to include IOTA Smart Contracts (ISC), a framework for programmable, decentralized agreements.

In IOTA, every address (derived from a user’s seed) can hold balances of the native IOTA token (MIOTA) and custom digital assets. Unlike traditional account-based blockchains, IOTA’s Tangle uses a UTXO ([Unspent Transaction Output](https://github.com/iotaledger/tips/blob/main/tips/TIP-0020/tip-0020.md#utxo)) model, where tokens are linked to addresses via outputs rather than stored in persistent accounts.

In IOTA, a foundational transaction type is the [user transaction](https://docs.iota.org/developer/iota-101/transactions/), which enables users to interact with smart contract and transfer assets, specially allow to send IOTA tokens (such as IOTA or MIOTA) between addresses. Each transaction specifies the sender’s address (which requires a valid cryptographic signature to authorize the transfer), the receiver’s address, and the amount of tokens being sent.Beyond basic value transfers, IOTA supports custom token transfers through its native tokenization framework.These transactions function allow users to create and send [custom assets](vhttps://docs.iota.org/developer/iota-101/create-coin/) by specifying the asset’s unique identifier, sender and receiver addresses, and the amount being transferred.

To coordinate multiple interdependent actions, IOTA uses atomic bundles like [PTBs](https://docs.iota.org/developer/iota-101/transactions/ptb/programmable-transaction-blocks), which group transactions into a single atomic unit. If any transaction in the bundle fails —due to invalid inputs, insufficient balances, or a smart contract error— all transactions in the bundle are discarded,guaranteeing atomicity. This is particularly useful for scenarios like conditional payments, where a user might bundle a token transfer with a smart contract call: if the contract fails to deliver a service, the payment is automatically reverted. Since IOTA transactions are feeless, users incur no costs even if a bundle fails, unlike fee-based blockchains where failed transactions might still deduct fees.

We will take a look at how a simple bet contract can be implemented in IOTA, using Move language.

### Logic Core

The fundamental unit of storage on IOTA is the object. Unlike many blockchains that focus on accounts containing key-value stores, IOTA's storage model centers around objects, each of which is addressable on-chain by a unique ID. In IOTA, a smart contract is an object known as a [package](https://docs.iota.org/references/framework/iota-framework/package), and these smart contracts interact with other objects on the IOTA network.

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
        addr: tx_context::sender(ctx),
        deadline: 600000 // 10 min
      };
      transfer::share_object(oracle);
  }
```
The function instantiates an oracle, which is subsequently shared across the chain via the [share_object](https://docs.iota.org/references/framework/testnet/iota-framework/transfer#function-share_object) function and get accessible the oracle instance for reads and writes by any transaction.

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
    let Bet {id: id,amount: wager, player1: p1, player2: p2,oracle: _, timeout: _} = bet;
    object::delete(id);
    let amount = wager.value();
    let mut wager = wager;

    let wager1 = wager.split(amount / 2, ctx);
    transfer::public_transfer(wager, p1);
    transfer::public_transfer(wager1, p2);
  }
```
The timeout function is publicly accessible, meaning anyone can trigger it. When called, it first checks —via an initial `assert` statement— whether the predefined time limit has expired. Only if this condition is confirmed will the function execute, redistributing all funds exclusively back to the original parties.

To achieve this, we first [unpack](https://docs.iota.org/developer/iota-101/move-overview/structs-and-abilities/struct#Unpacking-a-Stuct) the bet instance to close it and then we split the original coin into two equal halves and with the [public_transfer](https://docs.iota.org/references/framework/testnet/iota-framework/transfer#function-public_transfer) function each portion return back to its respective participant.



## Implementation differences

Below there are some of the most important differences in the bet implementation between Move diales like Aptos or SUI, and IOTA.

- **Aptos**: Use global ownership for all shared structs to enhance system security and employ local timestamps for deadline tracking

- **IOTA**: Use shared ownership for all shared structs to improve transaction parallelism, and rely on a global clock for deadline enforcement

- **SUI**: similar to IOTA’s design.

