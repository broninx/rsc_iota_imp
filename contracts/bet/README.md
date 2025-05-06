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


## Implementation differences

Below there are some of the most important differences in the bet implementation between Move diales like Aptos or SUI, and IOTA.

- **Aptos**: Use global ownership for all shared structs to enhance system security and employ local timestamps for deadline tracking

- **IOTA**: Use shared ownership for all shared structs to improve transaction parallelism, and rely on a global clock for deadline enforcement

- **SUI**: similar to IOTA’s design.

