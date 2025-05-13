module token_transfer::token_transfer;

use iota::coin::{Self, Coin};
use iota::iota::IOTA;
use iota::balance;

const EPermissionsDenied: u64 = 0;
const EBiggerThanBalance: u64 = 1;

public struct Wallet<phantom T> has key {
    id: UID,
    balance: balance::Balance<T>,
    owner: address,
    receiver: address,
    initialized: bool
} 

fun init( ctx: &mut TxContext){
    let wallet = Wallet {
        id: object::new(ctx),
        balance: balance::zero<IOTA>(),
        owner: ctx.sender(),
        receiver: ctx.sender(),
        initialized: false
    };
    transfer::share_object(wallet);
} 

public fun set_balance_and_receiver<T>(receiver: address,wallet: Wallet<IOTA>, ctx: &mut TxContext){
    assert!(!wallet.initialized, EPermissionsDenied);
    assert!(ctx.sender() == wallet.owner, EPermissionsDenied);
    let Wallet<IOTA> {id: uid, balance: balance, owner: owner, receiver: _, initialized: _} = wallet; 
    let wallet = Wallet<T>{
        id: object::new(ctx),
        balance: balance::zero<T>(),
        owner: owner,
        receiver: receiver,
        initialized: true
    };
    balance.destroy_zero();
    object::delete(uid);
    transfer::share_object(wallet);
}

public fun deposit<T>(amount: Coin<T>,wallet:&mut Wallet<T>, ctx: &mut TxContext){
    assert!(ctx.sender() == wallet.owner, EPermissionsDenied);
    
    let balance_to_deposite = coin::into_balance<T>(amount);
    wallet.balance.join(balance_to_deposite);
}

public fun withdrow<T>(amount: u64, wallet: &mut Wallet<T>, ctx: &mut TxContext){
    assert!(ctx.sender() == wallet.receiver, EPermissionsDenied);
    assert!(amount <= wallet.balance.value(), EBiggerThanBalance);

    let withdrow_balance = wallet.balance.split(amount);
    let withdrow_coin = coin::from_balance(withdrow_balance, ctx);
    transfer::public_transfer(withdrow_coin, wallet.receiver);
}

#[test_only]
public fun wallet_amount<T>(wallet: &Wallet<T>): u64 {
    wallet.balance.value()
}

entry fun initialize(ctx: &mut TxContext){
    let wallet = Wallet {
        id: object::new(ctx),
        balance: balance::zero<IOTA>(),
        owner: ctx.sender(),
        receiver: ctx.sender(),
        initialized: false
    };
    transfer::share_object(wallet);
}