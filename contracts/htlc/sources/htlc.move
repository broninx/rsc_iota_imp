module htlc::htlc;

use iota::coin::{Self, Coin};
use iota::balance::{Self, Balance};
use iota::hash;
use iota::iota::{Self, IOTA};
use iota::clock::{Self, Clock};

const EPermissionDenied: u64 = 0;
const EJustInitialized: u64 = 1;
const EWrongSecret: u64 = 2;
const ETimeNotFinished: u64 = 3;

public struct Htlc has key {
    id: UID,
    committer: address,
    receiver: address,
    hash: vector<u8>,
    deadline: u64,
    amount: Balance<IOTA>,
    initialized: bool
}

fun init(ctx: &mut TxContext){
    let htlc = Htlc {
        id: object::new(ctx),
        committer: ctx.sender(),
        receiver: ctx.sender(),
        hash: b"temp",
        deadline: 0,
        amount: balance::zero<IOTA>(),
        initialized: false
    };
    transfer::share_object(htlc);
}

public fun initialize(
    receiver: address,
    preimage: vector<u8>, 
    timeout: u64, 
    coin: Coin<IOTA>,
    htlc: Htlc,
    clock: &Clock, 
    ctx: &mut TxContext){
    assert!(ctx.sender() == htlc.committer, EPermissionDenied);
    assert!(!htlc.initialized, EJustInitialized);

    let Htlc {
        id: id, 
        committer: committer,
        receiver: _,
        hash: _,
        deadline: _,
        amount: mut htlc_balance,
        initialized: _
    } = htlc;

    let balance = coin::into_balance(coin);
    htlc_balance.join(balance);
    let htlc = Htlc {
        id: object::new(ctx),
        committer: committer,
        receiver: receiver,
        hash: hash::keccak256(&preimage),
        deadline: clock::timestamp_ms(clock) + timeout,
        amount: htlc_balance,
        initialized: true
    };
    id.delete();
    transfer::share_object(htlc);
}

public fun reveal(secret: vector<u8>, htlc: Htlc, ctx: &mut TxContext){
    assert!(ctx.sender() == htlc.committer, EPermissionDenied);
    assert!(htlc.hash == hash::keccak256(&secret), EWrongSecret);

    let Htlc {
        id: id,
        committer: committer,
        receiver: _,
        hash: _,
        deadline: _,
        amount: balance,
        initialized: _
    } = htlc;
    object::delete(id);
    let coin = coin::from_balance(balance, ctx);
    iota::transfer(coin, committer);
}

public fun timeout(clock: &Clock, htlc: Htlc, ctx: &mut TxContext){
    assert!(clock::timestamp_ms(clock) > htlc.deadline, ETimeNotFinished);
    let Htlc {
        id: id,
        committer: _,
        receiver: receiver,
        hash: _,
        deadline: _,
        amount: balance,
        initialized: _
    } = htlc;

    object::delete(id);
    let coin = coin::from_balance(balance, ctx);
    iota::transfer(coin, receiver);

}

#[test_only]
public fun init_test(ctx: &mut TxContext){
    let htlc = Htlc {
        id: object::new(ctx),
        committer: ctx.sender(),
        receiver: ctx.sender(),
        hash: b"temp",
        deadline: 0,
        amount: balance::zero<IOTA>(),
        initialized: false
    };
    transfer::share_object(htlc);
}

public fun deadline(self: &Htlc): u64{
    self.deadline
}