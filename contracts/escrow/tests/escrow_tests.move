
#[test_only]
module escrow::escrow_tests; 

use iota::iota::IOTA;
use escrow::escrow::{Self, Escrow};
use iota::test_scenario::{Self, Scenario};
use iota::coin::{Self, Coin};

const EPayBadImplementation: u64 = 3;
const ERefundBadImplementation: u64 = 4;

const SELLER: address = @0xCAFE;
const BUYER: address = @0xFACE;
const PAY: bool = true;
const REFUND: bool = false;

fun initialize_test(sender: address): Scenario{
    let mut scenario = test_scenario::begin(sender);
    let ctx = scenario.ctx();
    escrow::initialize(BUYER, 1000, ctx);
    scenario
}

fun deposit_test(amount: Coin<IOTA>, sender: address, mut scenario:Scenario): Scenario{

    scenario.next_tx(sender);
    let mut escrow = scenario.take_shared<Escrow>();
    let ctx = scenario.ctx();
    escrow::deposit(amount, &mut escrow, ctx);
    test_scenario::return_shared(escrow);
    scenario
}

fun pay_or_refund_test(pay: bool, sender: address, mut scenario: Scenario): Scenario{
    scenario.next_tx(sender);
    let escrow = scenario.take_shared<Escrow>();
    let ctx = test_scenario::ctx(&mut scenario);
    if (pay) { 
        escrow::pay(escrow, ctx); 
    } else { 
        escrow::refund(escrow, ctx); 
    };
    scenario
}

#[test]
public fun intended_way_pay(){
    let mut scenario = initialize_test(SELLER);
    
    let ctx = scenario.ctx();
    let amount = coin::mint_for_testing(1000, ctx);
    let scenario = deposit_test(amount, BUYER, scenario);

    let scenario = pay_or_refund_test(PAY, BUYER, scenario);
    assert!(!test_scenario::has_most_recent_shared<Escrow>(), EPayBadImplementation);
    scenario.end();
}

#[test]
public fun intended_way_refund(){
    let mut scenario = initialize_test(SELLER);

    let ctx = scenario.ctx();
    let amount = coin::mint_for_testing(1000, ctx);
    let scenario = deposit_test(amount, BUYER, scenario);

    let scenario = pay_or_refund_test(REFUND, SELLER, scenario);
    assert!(!test_scenario::has_most_recent_shared<Escrow>(), ERefundBadImplementation);
    scenario.end();
}

#[test, expected_failure(abort_code = escrow::EPermissionDenied)]
public fun wrong_depositer(){
    let mut scenario = initialize_test(SELLER);

    let ctx = scenario.ctx();
    let amount = coin::mint_for_testing<IOTA>(1000, ctx);
    let scenario = deposit_test(amount, SELLER, scenario);

    scenario.end();
}

#[test, expected_failure(abort_code = escrow::EPermissionDenied)]
public fun wrong_state_deposit(){
    let mut scenario = initialize_test(SELLER);

    let ctx = scenario.ctx();
    let amount = coin::mint_for_testing(1000, ctx);
    let mut scenario = deposit_test(amount, BUYER, scenario);

    let ctx = test_scenario::ctx(&mut scenario);
    let amount = coin::mint_for_testing(1000, ctx);
    let scenario = deposit_test(amount, BUYER, scenario);

    scenario.end();
}

#[test, expected_failure(abort_code = escrow::EWrongAmount)]
public fun wrong_amount(){
    let mut scenario = initialize_test(SELLER);

    let ctx = scenario.ctx();
    let amount = coin::mint_for_testing(999, ctx);
    let scenario = deposit_test(amount, BUYER, scenario);

    scenario.end();
}

#[test, expected_failure(abort_code = escrow::EPermissionDenied)]
public fun wrong_state_pay(){
    let mut scenario = initialize_test(SELLER);

    let scenario = pay_or_refund_test(PAY, BUYER, scenario);
    scenario.end();
}

#[test, expected_failure(abort_code = escrow::EPermissionDenied)]
public fun wrong_buyer_pay(){
    let mut scenario = initialize_test(SELLER);

    let ctx = scenario.ctx();
    let amount = coin::mint_for_testing(1000, ctx);
    let scenario = deposit_test(amount, BUYER, scenario);

    let scenario = pay_or_refund_test(PAY, SELLER, scenario);
    scenario.end();
}

#[test, expected_failure(abort_code = escrow::EPermissionDenied)]
public fun wrong_state_refund(){
    let mut scenario = initialize_test(SELLER);

    let scenario = pay_or_refund_test(REFUND, SELLER, scenario);
    scenario.end();
}

#[test, expected_failure(abort_code = escrow::EPermissionDenied)]
public fun wrong_seller_refund(){
    let mut scenario = initialize_test(SELLER);

    let ctx = scenario.ctx();
    let amount = coin::mint_for_testing(1000, ctx);
    let scenario = deposit_test(amount, BUYER, scenario);

    let scenario = pay_or_refund_test(REFUND, BUYER, scenario);
    scenario.end();
}

#[test, expected_failure(abort_code = test_scenario::EEmptyInventory)]
public fun pay_and_refund(){
    let mut scenario = initialize_test(SELLER);

    let ctx = scenario.ctx();
    let amount = coin::mint_for_testing(1000, ctx);
    let scenario = deposit_test(amount, BUYER, scenario);

    let scenario = pay_or_refund_test(PAY, BUYER, scenario);
    let scenario = pay_or_refund_test(REFUND, SELLER, scenario);
    scenario.end();
}