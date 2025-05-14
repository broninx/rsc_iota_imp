## About

A set of use cases with tests taken from [rosetta-smart-contracts](https://github.com/blockchain-unica/rosetta-smart-contracts) project implemented in Move/IOTA.

## Use cases

1. [Bet](contracts/bet)
2. [Simple transfer](contracts/simple_transfer)
3. [Token transfer](contracts/token_transfer)

## Installation

To install IOTA and all necessary dependencies you can see the [IOTA Installation guide](https://docs.iota.org/developer/getting-started/install-iota).

## Usage

To build a specific contract, navigate to the `./contracts/<target-contract-directory>` and run the following command:

```bash
iota move build
```

To run all tests for a specific contract, navigate to the `./contracts/<target-contract-directory>` directory and run the following command:

```bash
iota move test
```
