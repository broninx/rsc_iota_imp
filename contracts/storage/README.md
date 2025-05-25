# Storage

## Specification

The Storage contract allows a user to store on-chain byte sequences and strings (of arbitrary size).  

After contract creation, the contract supports two actions:
- **storeBytes**, which allows the user to store a sequence of bytes of arbitrary lenght;
- **storeString**, which allows the user to store a string of arbitrary length.

## Required functionalities

- Dynamic arrays

## Implementation differences

The Storage implementation retains the same discrepancies with other diales identified in the previous implementations.
