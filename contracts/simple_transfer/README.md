# Simple transfer

## Specification 

The contract allows a user (the *owner*) to deposit native cryptocurrency, 
and another user (the *recipient*) to withdraw arbitrary fractions of the contract balance.

At contract creation, the owner specifies the receiver's address.

After contract creation, the contract supports two actions:
- **deposit** allows the owner to deposit an arbitrary amount of native cryptocurrency in the contract;
- **withdraw** allows the receiver to withdraw any amount of the cryptocurrency deposited in the contract.

## Required functionalities

- Native tokens
- Transaction revert
