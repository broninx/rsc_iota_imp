
module vault::vault;

use iota::coin::{Self, Coin};
use iota::balance::{Self, Balance};
use iota::clock::Clock;

const EPermissionDenied: u64 = 0;
const ENotInitialized: u64 = 1;
const EWrongState: u64 = 2;
const EWrongTime: u64 = 3;
const ELowBalance:u64 = 4;

const INIT: u8 = 0;
const READY: u8 = 1; 
const ONGOING: u8 = 2;

public struct Owner has key, store {
    id: UID,
    addr: address
}

public struct Vault<phantom T> has key {
    id: UID,
    owner: address,
    receiver: address,
    amount: Balance<T>,
    withdrawal_amount: u64,
    recovery_key: vector<u8>,
    wait_time: u64,
    deadline: u64,
    state: u8 
}

fun init(ctx: &mut TxContext){
    let owner = Owner {
        id: object::new(ctx),
        addr: ctx.sender()
      };
    transfer::share_object(owner);
}

// wait_time is in seconds
public fun initialize<T>(recovery_key: vector<u8>, wait_time: u64, owner: Owner, ctx: &mut TxContext){
    assert!(ctx.sender() == owner.addr, EPermissionDenied);
    let Owner {id: id, addr: owner} = owner;
    let vault = Vault<T> {
        id: object::new(ctx),
        owner: owner,
        receiver: @0x0,
        amount: balance::zero<T>(),
        withdrawal_amount: 0,
        recovery_key: recovery_key,
        wait_time: wait_time * 1000,
        deadline: 0,
        state: READY
    };
    id.delete();
    transfer::share_object(vault);
}

public fun receive<T>(amount: Coin<T>, vault: &mut Vault<T>){
    assert!(vault.state != INIT, ENotInitialized);

    let amount = coin::into_balance(amount);
    vault.amount.join(amount);
}

public fun withdraw<T>(amount: u64, receiver: address, vault: &mut Vault<T>,clock: &Clock, ctx: &mut TxContext){
    assert!(vault.state == READY, ENotInitialized);
    assert!(ctx.sender() == vault.owner, EPermissionDenied);
    assert!(vault.amount.value() >= amount, ELowBalance);

    vault.receiver = receiver;
    vault.withdrawal_amount = amount;
    vault.deadline = clock.timestamp_ms() + vault.wait_time;
    vault.state = ONGOING;
}

public fun finalize<T>(vault: &mut Vault<T>, clock: &Clock, ctx: &mut TxContext){
    assert!(vault.state == ONGOING, EWrongState);
    assert!(vault.deadline <= clock.timestamp_ms(), EWrongTime);
    assert!(ctx.sender() == vault.owner, EPermissionDenied);

    let coin = coin::take( &mut vault.amount, vault.withdrawal_amount, ctx);
    transfer::public_transfer(coin, vault.receiver);
    vault.state = READY;
}

public fun cancel<T>(recovery_key: vector<u8>, vault: &mut Vault<T>, clock: &Clock, ctx: &mut TxContext){
    assert!(vault.state == ONGOING, EWrongState);
    assert!(vault.deadline > clock.timestamp_ms(), EWrongTime);
    assert!(ctx.sender() == vault.owner, EPermissionDenied);
    assert!(vault.recovery_key == recovery_key, EPermissionDenied);

    vault.state = READY;
}

#[test_only]
public fun init_test(ctx: &mut TxContext) {
    let owner = Owner {
        id: object::new(ctx),
        addr: ctx.sender()
    };
    transfer::share_object(owner);
}
