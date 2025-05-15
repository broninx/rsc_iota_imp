# HTLC

## Specification

The Hash Timed Locked Contract (HTLC) involves two users, the *committer* and the *receiver*.

At contract creation, the committer:
- deposits a collateral (in native cryptocurrency) in the contract;
- specifies a deadline for the secret revelation, in terms of a delay from the publication of the contract;
- specifies the receiver of the collateral, in case the deposit is not revealed within the deadline.
- commits to a value, that is the Keccak-256 digest of a secret bitstring chosen by the committer.

After contract creation, the contract supports two actions:
- **reveal**, which allows the committer to redeem the whole contract balance by providing a preimage of the committed hash;
- **timeout**, which can be called only after the deadline, and tranfers the whole contract balance to the receiver.

## Required functionalities

- Native tokens
- Time constraints
- Transaction revert
- Hash on arbitrary messages
