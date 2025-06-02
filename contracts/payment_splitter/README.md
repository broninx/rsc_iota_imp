# Payment Splitter

## Specification

This contract allows to split (native) cryptocurrency payments among a group of users. The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each account to a number of shares. 

At deployment, the contract creator specifies the set of users who will receive the payments and the corresponding number of shares. The set of shareholders and their shares cannot be updated thereafter. 

After creation, the contract supports the following actions:
- **receive**, which allows anyone to deposit cryptocurrency units in the contract;
- **release**, which allows anyone to distribute the contract balance to the shareholders. Each shareholder will receive an amount proportional to the percentage of total shares they were assigned. The contract follows a pull payment model: this means that each shareholder will receive the corresponding amount in a separate call to the release function.

## Required functionalities

- Native tokens
- Transaction revert
- Key-value maps
- Bounded loops

## Implementation

### Initialize

During contract deployment, an instance of the `Owner` struct (containing the owner's address) is created. This instance is passed as a parameter to the `initialize` function and immediately destroyed within it to enforce single-use initialization.

```move
public fun initialize<T>(shareolders: vector<address>, shares: vector<u64>, owner: Owner, ctx: &mut TxContext){
    assert!(ctx.sender() == owner.addr, EPermissionDenied);
    assert!(shareolders.length() == shares.length(), EWrongSharesDistribution);

    let Owner {id: id, addr: _} = owner;
    let mut shares_tot = 0;
    let mut vecmap_shareholders = vec_map::empty<address, ShareHolder<T>>();
    let mut i = 0;
    while (i < shares.length()){
        shares_tot = shares_tot + shares[i];
        let shareolder = ShareHolder {shares: shares[i], balance: balance::zero<T>()};
        vecmap_shareholders.insert(shareolders[i], shareolder);
        i = i + 1;
    };
    let payment_splitter = PaymentSplitter {
        id: object::new(ctx),
        shareholders: vecmap_shareholders,
        shares_tot,
        balance: balance::zero<T>()
    };
    id.delete();
    transfer::share_object(payment_splitter);
}

```
The initialize function accepts two arrays as parameters:
1. `shareholders` - an array of addresses
2. `shares` - an array of integers representing ownership percentages

These arrays must have identical lengths to maintain index correspondence - the shareholder at index **i** receives the share value at index **i**.

This data is stored in a mapping where:
- **Key**: Shareholder address
- **Value**: Shareholder struct instance containing:
  - `shares`: Assigned percentage of total shares
  - `balance`: Tokens allocated (but not yet released) to this shareholder

The mapping is encapsulated within a `PaymentSplitter` struct that also tracks:
- total shares: Sum of all shares for proportional distribution
- contract balance: Pool holding tokens deposited by users before distribution

### Receive and Release

`receive` function is a simple function that allow anyone to send tokens at the PaymentSplitter balance.

```move
public fun receive<T>(coin: Coin<T>, payment_splitter: &mut PaymentSplitter<T>){
    let balance = coin.into_balance();
    payment_splitter.balance.join(balance);
}
```

The `release` function may be called when the contract balance is greater than zero.

```move
public fun release<T>(payment_splitter: &mut PaymentSplitter<T>){
    assert!(payment_splitter.balance.value() > 0, EBalanceEmpty);
    let balance = &mut payment_splitter.balance;
    let balance_amount_per_share = balance.value() / payment_splitter.shares_tot;
    let mut i = 0;
    let keys = payment_splitter.shareholders.keys();
    while(i < keys.length()){
        let shareholder = payment_splitter.shareholders.get_mut(&keys[i]);
        let balance_i = balance.split(balance_amount_per_share * shareholder.shares);
        shareholder.balance.join(balance_i);
        i = i + 1;
    };
}
```
The `release` function distributes the contract's token `balance` proportionally to `shareholder` based on their assigned shares. The distribution algorithm works as follows:
1. Calculate the value per share: `balance.value()` / `payment_splitter.shares_tot`
2. For each shareholder:
   - Compute their allocation: `balance_amount_per_share` * `shareholder.shares`
   - Credit this amount to their individual `balance` in the `Shareholder` struct
  
### Take_amount

The `take_amount` function allows registered shareholders to withdraw their allocated token balances. Access is strictly limited to addresses recorded as keys in the PaymentSplitter mapping. Any call attempt by an unauthorized address triggers transaction termination with the `EKeyDoesNotExist` error code (thrown by the `get_mut` function of IOTA's `vec_map` module).

```move
public fun take_amount<T>(payment_splitter: &mut PaymentSplitter<T>, ctx: &mut TxContext){
    let sharesholder = payment_splitter.shareholders.get_mut(&ctx.sender());
    let value = sharesholder.balance.value();
    let coin = coin::take<T>(&mut sharesholder.balance, value, ctx);
    transfer::public_transfer(coin, ctx.sender());
}
```
