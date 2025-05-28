
#[test_only]
module token_transfer::token_transfer_tests;

use token_transfer::token_transfer::{Self, Wallet};
use iota::test_scenario::{Self as ts, Scenario};
use iota::coin;
use iota::iota::IOTA;

const EEmptyInventory: u64 = 3;

const OWNER : address = @0xCAFE;
const RECEIVER: address = @0xFACE;

fun setup(): Scenario{
    let mut scenario = ts::begin(OWNER);
    let ctx = scenario.ctx();
    token_transfer::initialize(ctx);
    scenario
}

fun deposit_test(amount: u64, sender: address, mut scenario: Scenario): Scenario{
    scenario.next_tx(sender);
    assert!(ts::has_most_recent_shared<Wallet<IOTA>>(), EEmptyInventory);
    let mut wallet = scenario.take_shared<Wallet<IOTA>>();
    let ctx = scenario.ctx();
    let coin = coin::mint_for_testing<IOTA>(amount, ctx);
    token_transfer::deposit(coin, &mut wallet, ctx);
    ts::return_shared(wallet);
    scenario
}

fun withdraw_test(amount: u64, sender: address, mut scenario: Scenario): Scenario{
    scenario.next_tx(sender);
    let mut wallet = scenario.take_shared<Wallet<IOTA>>();
    let ctx = scenario.ctx();
    token_transfer::withdraw(amount, &mut wallet, ctx); 
    ts::return_shared(wallet);
    scenario
}

#[test]
public fun intended_way() {
    let scenario = setup();

    let scenario = deposit_test(10000, OWNER, scenario);
    
    let scenario = withdraw_test(1000, RECEIVER, scenario);

    let scenario = withdraw_test(9000, RECEIVER, scenario);

    scenario.end();
}

#[test, expected_failure(abort_code = token_transfer::EPermissionsDenied)]
public fun unauthorized_set_receiver() {
    let mut scenario = setup();

    scenario.next_tx(RECEIVER);
    let wallet = scenario.take_shared<Wallet<IOTA>>();
    let ctx = scenario.ctx();
    token_transfer::set_balance_and_receiver<IOTA>(RECEIVER, wallet, ctx);
    
    scenario.end();
}

#[test, expected_failure(abort_code = token_transfer::EPermissionsDenied)]
public fun receiver_cant_deposit() {
    let scenario = setup();

    let scenario = deposit_test(1000, RECEIVER, scenario); 

    scenario.end();
}

#[test, expected_failure(abort_code = token_transfer::EPermissionsDenied)]
public fun only_receiver_withdraw() {
    let scenario = setup();

    let scenario = deposit_test(10000, OWNER, scenario); 

    let scenario = withdraw_test(10, OWNER, scenario); 

    scenario.end();
}

#[test, expected_failure(abort_code = token_transfer::EBiggerThanBalance)]
public fun withdorw_amount_bigger_than_balance() {
    let scenario = setup();

    let scenario = deposit_test(1000, OWNER, scenario); 

    let scenario = withdraw_test(1001, RECEIVER, scenario);

    scenario.end();
}

