
#[test_only]
module escrow::escrow_tests; 

use iota::iota::IOTA;
use escrow::escrow::{Self, Escrow};
use iota::test_scenario::{Self, Scenario};
use iota::coin::{Self, Coin};

const EEmptyInventory: u64 = 2;
const EPayBadImplementation: u64 = 3;
const ERefundBadImplementation: u64 = 4;

const SELLER: address = @0xCAFE;
const BUYER: address = @0xFACE;
const PAY: bool = true;
const REFUND: bool = false;

fun setup(): Scenario{
    let mut scenario = test_scenario::begin(SELLER);
    let ctx = test_scenario::ctx(&mut scenario);
    escrow::init_test(ctx);
    scenario
}

fun initialize_test(sender: address, mut scenario: Scenario): Scenario{

    test_scenario::next_tx(&mut scenario, sender);
    assert!(test_scenario::has_most_recent_shared<Escrow>(), EEmptyInventory);
    let mut escrow = test_scenario::take_shared<Escrow>(&scenario);
    let ctx = test_scenario::ctx(&mut scenario);
    escrow::initialize(BUYER, 1000, &mut escrow, ctx);
    test_scenario::return_shared(escrow);
    scenario
}

fun deposit_test(amount: Coin<IOTA>, sender: address, mut scenario:Scenario): Scenario{

    test_scenario::next_tx(&mut scenario, sender);
    let mut escrow = test_scenario::take_shared<Escrow>(&scenario);
    let ctx = test_scenario::ctx(&mut scenario);
    escrow::deposit(amount, &mut escrow, ctx);
    test_scenario::return_shared(escrow);
    scenario
}

fun pay_or_refund_test(pay: bool, sender: address, mut scenario: Scenario): Scenario{
    test_scenario::next_tx(&mut scenario, sender);
    let escrow = test_scenario::take_shared<Escrow>(&scenario);
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
    let mut scenario = initialize_test(SELLER, setup());
    
    let ctx = test_scenario::ctx(&mut scenario);
    let amount = coin::mint_for_testing(1000, ctx);
    let scenario = deposit_test(amount, BUYER, scenario);

    let scenario = pay_or_refund_test(PAY, BUYER, scenario);
    assert!(!test_scenario::has_most_recent_shared<Escrow>(), EPayBadImplementation);
    test_scenario::end(scenario);
}

#[test]
public fun intended_way_refund(){
    let mut scenario = initialize_test(SELLER, setup());

    let ctx = test_scenario::ctx(&mut scenario);
    let amount = coin::mint_for_testing(1000, ctx);
    let scenario = deposit_test(amount, BUYER, scenario);

    let scenario = pay_or_refund_test(REFUND, SELLER, scenario);
    assert!(!test_scenario::has_most_recent_shared<Escrow>(), ERefundBadImplementation);
    test_scenario::end(scenario);
}

#[test, expected_failure(abort_code = escrow::EPermissionDenied)]
public fun wrong_initializer(){
    let scenario = initialize_test(BUYER, setup());

    test_scenario::end(scenario);
}

#[test, expected_failure(abort_code = escrow::EPermissionDenied)]
public fun double_initialization(){
    let scenario = initialize_test(SELLER, setup());
    let scenario = initialize_test(SELLER, scenario);
    test_scenario::end(scenario);
}

#[test, expected_failure(abort_code = escrow::EPermissionDenied)]
public fun wrong_depositer(){
    let mut scenario = initialize_test(SELLER, setup());

    let ctx = test_scenario::ctx(&mut scenario);
    let amount = coin::mint_for_testing(1000, ctx);
    let scenario = deposit_test(amount, SELLER, scenario);

    test_scenario::end(scenario);
}

#[test, expected_failure(abort_code = escrow::EPermissionDenied)]
public fun wrong_state_deposit(){
    let mut scenario = initialize_test(SELLER, setup());

    let ctx = test_scenario::ctx(&mut scenario);
    let amount = coin::mint_for_testing(1000, ctx);
    let mut scenario = deposit_test(amount, BUYER, scenario);

    let ctx = test_scenario::ctx(&mut scenario);
    let amount = coin::mint_for_testing(1000, ctx);
    let scenario = deposit_test(amount, BUYER, scenario);

    test_scenario::end(scenario);
}

#[test, expected_failure(abort_code = escrow::EWrongAmount)]
public fun wrong_amount(){
    let mut scenario = initialize_test(SELLER, setup());

    let ctx = test_scenario::ctx(&mut scenario);
    let amount = coin::mint_for_testing(999, ctx);
    let scenario = deposit_test(amount, BUYER, scenario);

    test_scenario::end(scenario);
}

#[test, expected_failure(abort_code = escrow::EPermissionDenied)]
public fun wrong_state_pay(){
    let scenario = initialize_test(SELLER, setup());

    let scenario = pay_or_refund_test(PAY, BUYER, scenario);
    test_scenario::end(scenario);
}

#[test, expected_failure(abort_code = escrow::EPermissionDenied)]
public fun wrong_buyer_pay(){
    let mut scenario = initialize_test(SELLER, setup());

    let ctx = test_scenario::ctx(&mut scenario);
    let amount = coin::mint_for_testing(1000, ctx);
    let scenario = deposit_test(amount, BUYER, scenario);

    let scenario = pay_or_refund_test(PAY, SELLER, scenario);
    test_scenario::end(scenario);
}

#[test, expected_failure(abort_code = escrow::EPermissionDenied)]
public fun wrong_state_refund(){
    let scenario = initialize_test(SELLER, setup());

    let scenario = pay_or_refund_test(REFUND, SELLER, scenario);
    test_scenario::end(scenario);
}

#[test, expected_failure(abort_code = escrow::EPermissionDenied)]
public fun wrong_seller_refund(){
    let mut scenario = initialize_test(SELLER, setup());

    let ctx = test_scenario::ctx(&mut scenario);
    let amount = coin::mint_for_testing(1000, ctx);
    let scenario = deposit_test(amount, BUYER, scenario);

    let scenario = pay_or_refund_test(REFUND, BUYER, scenario);
    test_scenario::end(scenario);
}

#[test, expected_failure(abort_code = test_scenario::EEmptyInventory)]
public fun pay_and_refund(){
    let mut scenario = initialize_test(SELLER, setup());

    let ctx = test_scenario::ctx(&mut scenario);
    let amount = coin::mint_for_testing(1000, ctx);
    let scenario = deposit_test(amount, BUYER, scenario);

    let scenario = pay_or_refund_test(PAY, BUYER, scenario);
    let scenario = pay_or_refund_test(REFUND, SELLER, scenario);
    test_scenario::end(scenario);
}