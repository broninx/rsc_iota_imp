# Token transfer

## Specification 

The contract TokenTransfer allows a user (the *owner*)
to transfer units of a token (possibly, not the native cryptocurrency) to the contract, 
and another user (the *recipient*) to withdraw.

At contract creation, the owner specifies the receiver's address and the token address.

After contract creation, the contract supports two actions:
- **deposit**, which allows the owner to deposit an arbitrary amount of tokens
in the contract;
- **withdraw**, which allows the receiver to withdraw 
any amount of the token deposited in the contract.

## Required functionalities
- Custom tokens
- Transaction revert
  
