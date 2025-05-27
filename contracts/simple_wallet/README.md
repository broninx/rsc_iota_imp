# Simple Wallet

## Specification

The SimpleWallet contract acts as a native cryptocurrency deposit, and it allows for the creation and execution of transactions to a specific address. 
The owner can withdraw the total amount of cryptocurrency in the balance at any time.

The owner initializes the contract by specifying the address that they want to authorize. 

After contract creation, the contract supports the following actions:
- **deposit**, which allows the owner to deposit any amount of native cryptocurrency; 
- **createTransaction**, which allows the owner to create a transaction. The transaction specifies its recipient, value, and a data field;
- **executeTransaction**, which allows the owner to execute the transaction, specifying the transaction ID. This transaction will be successful only if the contract balance is sufficient and if the transaction ID exists and has not yet been executed; 
- **withdraw**, which allows the owner to withdraw the entire contract balance.

## Required functionalities

- Native tokens
- Transaction revert
- Dynamic arrays
