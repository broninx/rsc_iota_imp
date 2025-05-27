## About

A set of use cases with tests taken from [rosetta-smart-contracts](https://github.com/blockchain-unica/rosetta-smart-contracts) project implemented in Move/IOTA.

## Use cases

1. [Bet](contracts/bet)
2. [Simple transfer](contracts/simple_transfer)
3. [Token transfer](contracts/token_transfer)
4. [HTLC](contracts/htlc)
5. [Escrow](contracts/escrow)
6. [Auction](contracts/auction)
7. [Crowdfund](contracts/crowdfund)
8. [Vault](contracts/vault)
9. [Vesting](contracts/vesting)
10. [Storage](contracts/storage)
11. [Simple wallet](contracts/simple_wallet)

## Installation

To install IOTA and all necessary dependencies you can see the [IOTA Installation guide](https://docs.iota.org/developer/getting-started/install-iota).

## Usage

Before running any commands, ensure you're in the target contract's directory:

```bash
$ cd ~/<path>/rsc_iota_imp/contracts/<target-contract>
```

To build the contract run the following command:

```bash

$ iota move build
```

To run all tests run the following command:

```bash
$ iota move test
```
