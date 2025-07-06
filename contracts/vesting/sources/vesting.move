
module vesting::vesting;

use iota::balance::Balance;
use iota::iota::IOTA;
use iota::coin::{Self, Coin};
use iota::clock::Clock;
use 0x1::u64::{max, min};

const EPermissionDenied: u64 = 0;


public struct Vesting has key {
    id: UID,
    owner: address,
    beneficiary: address,
    start: u64,
    end: u64,
    balance: Balance<IOTA>,
}

public fun initialize(beneficiary: address, start: u64, duration: u64, amount: Coin<IOTA>, 
    clock: &Clock, ctx: &mut TxContext){
    let vesting = Vesting {
        id: object::new(ctx),
        owner: ctx.sender(),
        beneficiary: beneficiary,
        start: start + clock.timestamp_ms(),
        end: start + duration + clock.timestamp_ms(),
        balance: coin::into_balance(amount),
    };
    transfer::share_object(vesting);
}

public fun release(vesting: &mut Vesting, clock: &Clock, ctx: &mut TxContext){
    assert!(vesting.beneficiary == ctx.sender(), EPermissionDenied);

    let clamped_time = max(vesting.start, min(vesting.end, clock.timestamp_ms()));
    let amount = vesting.balance.value() * (clamped_time - vesting.start)/ (vesting.end - vesting.start);
    let coin = coin::take(&mut vesting.balance, amount, ctx);
    transfer::public_transfer(coin, vesting.beneficiary);
}

#[test_only]

public fun value(self: & Vesting): u64 {
    self.balance.value()
} 
