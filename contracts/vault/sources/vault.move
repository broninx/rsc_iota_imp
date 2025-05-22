
module vault::vault;

use iota::coin::{Self, Coin};
use iota::balance::{Self, Balance};
use iota::iota::IOTA;
use iota::clock::Clock;

const EPermissionDenied: u64 = 0;
const ENotInitialized: u64 = 1;
const EWrongState: u64 = 2;
const EWrongTime: u64 = 3;
const ELowBalance:u64 = 4;

const INIT: u8 = 0;
const READY: u8 = 1; 
const ONGOING: u8 = 2;

public struct Vault<phantom T> has key {
    id: UID,
    owner: address,
    amount: Balance<T>,
    withdrawal_amount: u64,
    recovery_key: vector<u8>,
    wait_time: u64,
    remaining_time: u64,
    state: u8 
}

fun init(ctx: &mut TxContext){
    let vault = Vault {
        id: object::new(ctx),
        owner: ctx.sender(),
        amount: balance::zero<IOTA>(),
        withdrawal_amount: 0,
        recovery_key: b"",
        wait_time: 0,
        remaining_time: 0,
        state: INIT
    };
    transfer::share_object(vault);
}

public fun initialize<T>(recovery_key: vector<u8>, wait_time: u64, vault: Vault<IOTA>, ctx: &mut TxContext){
    assert!(vault.state == INIT, EPermissionDenied);
    assert!(ctx.sender() == vault.owner, EPermissionDenied);
    let Vault {
        id: id,
        owner: owner,
        amount: old_balance,
        withdrawal_amount: _,
        recovery_key: _,
        wait_time: _,
        remaining_time: _,
        state: _
    } = vault;
    old_balance.destroy_zero();
    object::delete(id);
    let vault = Vault<T> {
        id: object::new(ctx),
        owner: owner,
        amount: balance::zero<T>(),
        withdrawal_amount: 0,
        recovery_key: recovery_key,
        wait_time: wait_time,
        remaining_time: 0,
        state: READY
    };
    transfer::share_object(vault);
}

public fun receive<T>(amount: Coin<T>, vault: &mut Vault<T>){
    assert!(vault.state != INIT, ENotInitialized);

    let amount = coin::into_balance(amount);
    vault.amount.join(amount);
}

public fun withdraw<T>(amount: u64, vault: &mut Vault<T>,clock: &Clock, ctx: &mut TxContext){
    assert!(vault.state == READY, ENotInitialized);
    assert!(ctx.sender() == vault.owner, EPermissionDenied);
    assert!(vault.amount.value() >= amount, ELowBalance);

    vault.withdrawal_amount = amount;
    vault.remaining_time = clock.timestamp_ms() + vault.wait_time;
    vault.state = ONGOING;
}

public fun finalize<T>(vault: &mut Vault<T>, clock: &Clock, ctx: &mut TxContext){
    assert!(vault.state == ONGOING, EWrongState);
    assert!(vault.remaining_time >= clock.timestamp_ms(), EWrongTime);
    assert!(ctx.sender() == vault.owner, EPermissionDenied);

    let withdrawal_amount = vault.amount.split(vault.withdrawal_amount);
    let withdrawal_amount = coin::from_balance(withdrawal_amount, ctx);
    transfer::public_transfer(withdrawal_amount, vault.owner);
    vault.state = READY;
}

public fun cancel<T>(recovery_key: vector<u8>, vault: &mut Vault<T>, clock: &Clock, ctx: &mut TxContext){
    assert!(vault.state == ONGOING, EWrongState);
    assert!(vault.remaining_time < clock.timestamp_ms(), EWrongTime);
    assert!(ctx.sender() == vault.owner, EPermissionDenied);
    assert!(vault.recovery_key == recovery_key, EPermissionDenied);

    vault.state = READY;
}

