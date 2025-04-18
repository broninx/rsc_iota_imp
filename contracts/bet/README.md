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

## Implementation differences

Below there are some of the most important differences in the bet implementation between Move diales like Aptos or SUI, and IOTA.

- **Aptos**: Use global ownership for all shared structs to enhance system security and employ local timestamps for deadline tracking

- **IOTA**: Use shared ownership for all shared structs to improve transaction parallelism, and rely on a global clock for deadline enforcement

- **SUI**: similar to IOTA’s design.

