
/// Module: escrow
module escrow::escrow;

use iota::balance::{Self, Balance};
use iota::iota::IOTA;
use iota::coin::{Self, Coin};

const EPermissionDenied: u64 = 0;
const EWrongAmount: u64 = 1;

const IDLE: u8 = 0;
const ACTIVE: u8 = 1;

public struct Escrow has key {
    id: UID,
    buyer: address,
    seller: address,
    amount_required: u64,
    amount: Balance<IOTA>,
    state: u8
}

fun init(ctx: &mut TxContext){
    let escrow = Escrow {
        id: object::new(ctx),
        buyer: ctx.sender(),
        seller: ctx.sender(),
        amount_required: 0,
        amount: balance::zero<IOTA>(),
        state: IDLE
    };
    transfer::share_object(escrow);
}

public fun initialize (buyer: address, amount_required: u64, escrow: &mut Escrow){
    escrow.buyer = buyer;
    escrow.amount_required = amount_required;
}

public fun deposit(amount: Coin<IOTA>, escrow: &mut Escrow, ctx: &mut TxContext){
    assert!(ctx.sender() == escrow.buyer, EPermissionDenied);
    assert!(escrow.amount_required == amount.value(), EWrongAmount);
    assert!(escrow.state == IDLE, EPermissionDenied);

    let amount = coin::into_balance(amount);
    escrow.amount.join(amount);
    escrow.state = ACTIVE;
}

fun send_balance(recipient: address, escrow: Escrow, ctx: &mut TxContext){
    let Escrow {id: id, buyer: _, seller: _, amount_required: _, amount: balance, state: _} = escrow;
    let coin = coin::from_balance(balance, ctx);
    transfer::public_transfer(coin, recipient);   
    object::delete(id);
}

public fun pay(escrow: Escrow, ctx: &mut TxContext){
    assert!(escrow.buyer == ctx.sender(), EPermissionDenied);
    assert!(escrow.state == ACTIVE, EPermissionDenied);

    send_balance(escrow.seller, escrow, ctx);
}

public fun refund(escrow: Escrow, ctx: &mut TxContext){
    assert!(escrow.seller == ctx.sender(), EPermissionDenied);
    assert!(escrow.state == ACTIVE, EPermissionDenied);

    send_balance(escrow.buyer, escrow, ctx);
}