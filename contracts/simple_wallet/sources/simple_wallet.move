
module simple_wallet::simple_wallet;

use iota::iota::IOTA;
use iota::balance::{Self, Balance};
use iota::coin::{Self, Coin};

const EPermissionDenied: u64 = 0;
const EInvalidId: u64 = 1;
const ELowBalance: u64 = 2;

public struct Wallet has key {
    id: UID,
    owner: address,
    balance: Balance<IOTA>,
    transactions: vector<Transaction>
}

public struct Transaction has drop, store {
    id: ID,
    recipient: address,
    value: u64,
    data: vector<u8>
}

fun init(ctx: &mut TxContext){
    let wallet = Wallet {
        id: object::new(ctx),
        owner: ctx.sender(),
        balance: balance::zero<IOTA>(),
        transactions: vector::empty<Transaction>()
    };
    transfer::share_object(wallet);
}

public fun deposit(coin: Coin<IOTA>, wallet: &mut Wallet, ctx: &mut TxContext){
    assert!(ctx.sender() == wallet.owner, EPermissionDenied);

    wallet.balance.join(coin::into_balance(coin));
}

public fun createTransaction(recipient: address, value: u64, data: vector<u8>, wallet: &mut Wallet, ctx: &mut TxContext){
    assert!(ctx.sender() == wallet.owner, EPermissionDenied);
    let uid = object::new(ctx);
    let transaction = Transaction {
        id: *uid.as_inner(),
        recipient: recipient,
        value: value,
        data: data
    };
    wallet.transactions.push_back(transaction);
    object::delete(uid);
}

fun extract(transactions: &mut vector<Transaction>, id: ID): Option<Transaction>{
    let mut i = 0;
    let mut transaction = option::none();
    while( i < transactions.length<Transaction>() ){
        if (transactions[i].id == id){
            transaction = option::some(transactions.remove<Transaction>(i));
            break
        };
        i = i + 1;
    };
    transaction
} 

public fun executeTransaction(id: ID, wallet: &mut Wallet, ctx: &mut TxContext){
    let mut transaction_opt = extract(&mut wallet.transactions, id);
    assert!(ctx.sender() == wallet.owner, EPermissionDenied);
    assert!(transaction_opt.is_some(), EInvalidId);
    let transaction = transaction_opt.extract();
    assert!(transaction.value <= wallet.balance.value(), ELowBalance);

    let coin = coin::take(&mut wallet.balance, transaction.value, ctx);
    transfer::public_transfer(coin, transaction.recipient);
}

public fun withdraw(value: u64, wallet: &mut Wallet, ctx: &mut TxContext){
    assert!(ctx.sender() == wallet.owner, EPermissionDenied);
    assert!(value <= wallet.balance.value(), ELowBalance);

    let coin = coin::take(&mut wallet.balance, value, ctx);
    transfer::public_transfer(coin, wallet.owner);
}

#[test_only]
public fun init_test(ctx: &mut TxContext){
    let wallet = Wallet {
        id: object::new(ctx),
        owner: ctx.sender(),
        balance: balance::zero<IOTA>(),
        transactions: vector::empty<Transaction>()
    };
    transfer::share_object(wallet);
}

public fun transactions(self: &mut Wallet): &mut vector<Transaction>{
    &mut self.transactions
}
public fun id(transactions: &vector<Transaction>, i: u64): ID{
    transactions[i].id
}