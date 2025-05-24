# Vesting

## Specification

The contract handles the maturation (vesting) of native cryptocurrency for a given beneficiary. 

The contract is initialized by setting: 
- the address of the beneficiary,
- the first block height (start) where the beneficiary can withdraw funds,
- the overall duration of the vesting scheme,
- the initial balance, in native cryptocurrency.
 
After creation, the contract supports the following action:
- **release**, which allows the beneficiary to withdraw part of the vested amount, according to the following policy:
  - before the start block, the amount is zero;
  - at any moment between the start and the expiration of the vesting scheme, the amount is proportional to the time passed since the start of the scheme; 
  - once the scheme is expired, the amount is the entire contract balance. 

## Required functionalities

- Native tokens
- Time constraints
- Transaction revert
