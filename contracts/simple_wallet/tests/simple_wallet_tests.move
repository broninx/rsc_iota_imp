
#[test_only]
module simple_wallet::simple_wallet_tests;

use simple_wallet::simple_wallet::{Self as sw, Wallet};
use iota::test_scenario::{Self as ts, Scenario};
use iota::coin;
use iota::iota::IOTA;

const OWNER: address = @0xCAFE;
const RECIPIENT: address = @0xFACE;

public enum Action { Deposit, Create, Withdraw}

fun setup(): Scenario {
    let mut scenario = ts::begin(OWNER);
    let ctx = scenario.ctx();
    sw::init_test(ctx);
    scenario
}

fun deposit_test(amount: u64, sender: address, mut scenario: Scenario): Scenario{
    scenario.next_tx(sender);
    let mut wallet = scenario.take_shared<Wallet>();
    let ctx = scenario.ctx();
    let coin = coin::mint_for_testing<IOTA>(amount, ctx);
    sw::deposit(coin, &mut wallet, ctx);
    ts::return_shared(wallet);
    scenario
}

fun create_test(amount: u64, sender: address, mut scenario: Scenario): (Scenario, ID){
    scenario.next_tx(sender);
    let mut wallet = scenario.take_shared<Wallet>();
    let ctx = scenario.ctx();
    sw::createTransaction(RECIPIENT, amount, b"gift", &mut wallet, ctx);
    let transactions = wallet.transactions();
    let id = sw::id(transactions, transactions.length()-1);
    ts::return_shared(wallet);
    (scenario, id)
}

fun withdraw_test(amount: u64, sender: address, mut scenario: Scenario): Scenario{
    scenario.next_tx(sender);
    let mut wallet = scenario.take_shared<Wallet>();
    let ctx = scenario.ctx();
    sw::withdraw(amount, &mut wallet, ctx);
    ts::return_shared(wallet);
    scenario
}

fun executeTransaction_test(id: ID, sender: address, mut scenario: Scenario): Scenario{
    scenario.next_tx(sender);
    let mut wallet = scenario.take_shared<Wallet>();
    let ctx = scenario.ctx();
    sw::executeTransaction(id, &mut wallet, ctx);
    ts::return_shared(wallet);
    scenario
}

#[test]
public fun intended_way_general(){
    let scenario = setup();
    let scenario = deposit_test(1000, OWNER, scenario);
    let (scenario, id0) = create_test(1000, OWNER, scenario);
    let scenario = withdraw_test(500, OWNER, scenario);
    let scenario = deposit_test(1000, OWNER, scenario);
    let (scenario, id1) = create_test(2000, OWNER, scenario);
    let scenario = executeTransaction_test(id0 , OWNER, scenario);
    let scenario = deposit_test(5000, OWNER, scenario);
    let scenario = executeTransaction_test(id1, OWNER, scenario);
    scenario.end();
}

#[test, expected_failure(abort_code = sw::EInvalidId)]
public fun id_not_in_transactions(){
    let scenario = setup();
    let mut scenario = deposit_test(1000, OWNER, scenario);
    let ctx = scenario.ctx();
    let uid = object::new(ctx);
    let id = uid.to_inner();
    uid.delete();
    let scenario = executeTransaction_test(id, OWNER, scenario);
    scenario.end();
}

#[test, expected_failure(abort_code = sw::ELowBalance)]
public fun low_balance(){
    let scenario = setup();
    let scenario = deposit_test(1000, OWNER, scenario);
    let (scenario, id0) = create_test(1000, OWNER, scenario);
    let scenario = withdraw_test(500, OWNER, scenario);
    let scenario = executeTransaction_test(id0 , OWNER, scenario);
    scenario.end();
}