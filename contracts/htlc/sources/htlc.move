module htlc::htlc;

use iota::coin::{Self, Coin};
use iota::hash;
use iota::iota::{Self, IOTA};
use iota::clock::{Self, Clock};

const EPermissionDenied: u64 = 0;
const EJustInitialized: u64 = 1;
const EWrongSecret: u64 = 2;
const ETimeNotFinished: u64 = 3;

public struct Htlc has key {
    id: UID,
    owner: address,
    receiver: address,
    hash: vector<u8>,
    reveal_timeout: u64,
    coin: Coin<IOTA>,
    initialized: bool
}

fun init(ctx: &mut TxContext){
    let htlc = Htlc {
        id: object::new(ctx),
        owner: ctx.sender(),
        receiver: ctx.sender(),
        hash: b"temp",
        reveal_timeout: 0,
        coin: coin::zero<IOTA>(ctx),
        initialized: false
    };
    transfer::share_object(htlc);
}

public fun initialize(
    receiver: address,
    hash: vector<u8>, 
    timeout: u64, 
    coin: Coin<IOTA>,
    htlc: Htlc,
    clock: &Clock, 
    ctx: &mut TxContext){
    assert!(ctx.sender() == htlc.owner, EPermissionDenied);
    assert!(!htlc.initialized, EJustInitialized);

    let Htlc {
        id: id, 
        owner: owner,
        receiver: _,
        hash: _,
        reveal_timeout: _,
        coin: htlc_coin,
        initialized: _
    } = htlc;

    let mut htlc_balance = coin::into_balance(htlc_coin);
    let balance = coin::into_balance(coin);
    htlc_balance.join(balance);
    let htlc_coin = coin::from_balance(htlc_balance, ctx);
    let htlc = Htlc {
        id: object::new(ctx),
        owner: owner,
        receiver: receiver,
        hash: hash,
        reveal_timeout: clock::timestamp_ms(clock) + timeout,
        coin: htlc_coin,
        initialized: true
    };
    object::delete(id);
    transfer::share_object(htlc);
}

public fun reveal(secret: vector<u8>, htlc: Htlc, ctx: &mut TxContext){
    assert!(ctx.sender() == htlc.owner, EPermissionDenied);
    assert!(hash::keccak256(&htlc.hash) == hash::keccak256(&secret), EWrongSecret);

    let Htlc {
        id: id,
        owner: owner,
        receiver: _,
        hash: _,
        reveal_timeout: _,
        coin: coin,
        initialized: _
    } = htlc;
    object::delete(id);
    iota::transfer(coin, owner);
}

public fun timeout(clock: &Clock, htlc: Htlc){
    assert!(clock::timestamp_ms(clock) > htlc.reveal_timeout, ETimeNotFinished);
    let Htlc {
        id: id,
        owner: _,
        receiver: receiver,
        hash: _,
        reveal_timeout: _,
        coin: coin,
        initialized: _
    } = htlc;

    object::delete(id);
    iota::transfer(coin, receiver);

}

#[test_only]
public fun init_test(ctx: &mut TxContext){
    let htlc = Htlc {
        id: object::new(ctx),
        owner: ctx.sender(),
        receiver: ctx.sender(),
        hash: b"temp",
        reveal_timeout: 0,
        coin: coin::zero<IOTA>(ctx),
        initialized: false
    };
    transfer::share_object(htlc);
}

public fun reveal_timeout(self: &Htlc): u64{
    self.reveal_timeout
}