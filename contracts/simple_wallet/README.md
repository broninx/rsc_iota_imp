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

## Implementation

### Init

```move
public fun initialize(ctx: &mut TxContext){
    let wallet = Wallet {
        id: object::new(ctx),
        owner: ctx.sender(),
        balance: balance::zero<IOTA>(),
        transactions: vec_map::empty<ID, Transaction>()
    };
    transfer::public_transfer(wallet, ctx.sender());
}
```
In this design, the Wallet struct is created as an owned object during initialization rather than a shared resource. This fundamental architectural choice ensures that only the wallet's owner possesses both the cryptographic keys and the actual object reference required to interact with it. Since every function that modifies the wallet must receive the Wallet object itself as an explicit parameter, the Move runtime automatically enforces strict ownership verification before any operation can execute. The wallet's existence as an exclusively owned entity means functions require no additional sender validation - the mere presence of the wallet object in the transaction serves as cryptographic proof of authorization. This approach inherently prevents unauthorized access while eliminating redundant permission checks.

### Create transaction

```move
public fun createTransaction(recipient: address, value: u64, data: vector<u8>, wallet: &mut Wallet, ctx: &mut TxContext){
    let uid = object::new(ctx);
    let transaction = Transaction {
        recipient: recipient,
        value: value,
        data: data
    };
    wallet.transactions.insert(*uid.as_inner(), transaction);
    object::delete(uid);
}
```
The createTransaction function enables a wallet owner to initiate a new transaction by specifying three core parameters:
- recipient: The destination address
- value: The amount of tokens to transfer
- data: A custom payload represented as a vector<u8> (Move's string equivalent)

Upon execution, this function constructs a Transaction struct containing these parameters and appends it to the wallet's internal transaction list. This queue-based approach maintains an auditable record of pending transactions within the wallet's state while deferring actual blockchain operations to subsequent processing steps.

The UID struct is IOTA Move's way of making sure every on-chain object has a completely unique identity. It wraps around a core ID value to provide this guarantee. When creating transactions, we follow a careful two-step approach: First, we generate a new UID and extract its unique ID value. Then, we immediately destroy the original UID container. This ensures every transaction ID remains truly one-of-a-kind - you can be confident there are no duplicates anywhere in the blockchain's records.

### executeTransaction

```move
public fun executeTransaction(id: ID, wallet: &mut Wallet, ctx: &mut TxContext){
    let mut transaction_opt = wallet.transactions.try_get(&id);
    assert!(transaction_opt.is_some(), EInvalidId);
    let transaction = transaction_opt.extract();
    assert!(transaction.value <= wallet.balance.value(), ELowBalance);
    wallet.transactions.remove(&id);
    let coin = coin::take(&mut wallet.balance, transaction.value, ctx);
    transfer::public_transfer(coin, transaction.recipient);
}
```
The executeTransaction function enables wallet owners to process pending transactions by specifying a transaction ID. It works by:
1. Retrieve the specific transaction from the wallet's transaction queue
2. Verifying two critical conditions:
   - The transaction exists
   - The wallet balance is sufficient to cover the transfer amount
3. If both conditions are satisfied, executing the transfer of specified tokens to the recipient.

## Differences

### Dialect differences

The simple wallet implementation retains the same discrepancies with other diales identified in the previous implementations.

### Implementation differences

#### Aptos
- Maintains a pending transactions array within each Wallet struct
- Uses the transaction's index in this wallet-specific array as its ID
- Transaction execution references this index

#### IOTA
- Generates a new unique ID (UID) during transaction creation
- The UID is cryptographically derived from transaction content
- Transaction ID is extracted ("unwrapped") from this UID

#### Sui
- No wallet-level transaction lists maintained
- Transactions are self-contained objects stored on-chain
- `executeTransaction` consumes full transaction objects (not IDs)
