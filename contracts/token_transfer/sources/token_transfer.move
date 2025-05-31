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

public struct Owner has key, store {
    id: UID, 
    addr: address
  }

fun init( ctx: &mut TxContext){
    let owner = Owner {
        id: object::new(ctx),
        addr: ctx.sender()
    };
    transfer::public_freeze_object(owner);
} 

public fun set_balance_and_receiver<T>(receiver: address, owner: &Owner, ctx: &mut TxContext){
    assert!(ctx.sender() == owner.addr, EPermissionsDenied);
    let wallet = Wallet<T>{
        id: object::new(ctx),
        balance: balance::zero<T>(),
        owner: owner.addr,
        receiver: receiver,
        initialized: true
    };
    transfer::share_object(wallet);
}

public fun deposit<T>(amount: Coin<T>,wallet:&mut Wallet<T>, ctx: &mut TxContext){
    assert!(ctx.sender() == wallet.owner, EPermissionsDenied);
    
    let balance_to_deposite = coin::into_balance<T>(amount);
    wallet.balance.join(balance_to_deposite);
}

public fun withdraw<T>(amount: u64, wallet: &mut Wallet<T>, ctx: &mut TxContext){
    assert!(ctx.sender() == wallet.receiver, EPermissionsDenied);
    assert!(amount <= wallet.balance.value(), EBiggerThanBalance);

    let withdraw_coin = coin::take<T>(&mut wallet.balance, amount, ctx);
    transfer::public_transfer(withdraw_coin, wallet.receiver);
}

#[test_only]
public fun wallet_amount<T>(wallet: &Wallet<T>): u64 {
    wallet.balance.value()
}

entry fun initialize(ctx: &mut TxContext){
  let owner = Owner {
      id: object::new(ctx),
      addr: ctx.sender()
    };
    let wallet = Wallet {
        id: object::new(ctx),
        balance: balance::zero<IOTA>(),
        owner: ctx.sender(),
        receiver: @0xFACE,
        initialized: false
    };
    transfer::share_object(wallet);
    transfer::public_freeze_object(owner);
}
