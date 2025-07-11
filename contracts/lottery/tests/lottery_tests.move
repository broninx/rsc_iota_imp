
#[test_only]
module lottery::lottery_tests; 

use iota::test_scenario::{Self as ts, Scenario};
use lottery::lottery::{Self, Lottery};
use iota::clock::{Self, Clock};
use iota::hash::keccak256;
use iota::iota::IOTA;
use iota::coin;
use iota::random;

const PLAYER1: address = @0xCAFE;
const PLAYER2: address = @0xFACE;
const USER: address = @0xACEF;

fun join1_test(): (Scenario, Clock) {
    let mut scenario = ts::begin(PLAYER1);
    let ctx = scenario.ctx();
    let clock = clock::create_for_testing(ctx);
    let coin = coin::mint_for_testing<IOTA>(1000, ctx);
    let hash = keccak256(&b"hello");
    lottery::join1(10, coin, hash, &clock, ctx);
    (scenario, clock)
}

fun join2_test(value: u64, hash: vector<u8>, clock: &Clock, mut scenario: Scenario): Scenario {
    scenario.next_tx(PLAYER2);
    let mut lottery = scenario.take_shared<Lottery<IOTA>>();
    let ctx = scenario.ctx();
    let coin = coin::mint_for_testing<IOTA>(value, ctx);
    lottery::join2(coin, hash, clock, &mut lottery, ctx);
    ts::return_shared(lottery);
    scenario
}

fun redeem_commit_test(sender: address, clock: &Clock, mut scenario: Scenario){
    scenario.next_tx(sender);
    let lottery = scenario.take_shared<Lottery<IOTA>>();
    let ctx = scenario.ctx();
    lottery::redeem_commit(clock, lottery, ctx);
    scenario.end();
}

fun reveal1_test(sender: address, secret: vector<u8>, clock: &Clock, mut scenario: Scenario): Scenario{
    scenario.next_tx(sender);
    let mut lottery = scenario.take_shared<Lottery<IOTA>>();
    let ctx = scenario.ctx();
    lottery::reveal1(secret, clock, &mut lottery, ctx);
    ts::return_shared(lottery);
    scenario
}

fun reveal2_test(sender: address, secret: vector<u8>, clock: &Clock, mut scenario: Scenario): Scenario{
    scenario.next_tx(sender);
    let mut lottery = scenario.take_shared<Lottery<IOTA>>();
    let ctx = scenario.ctx();
    lottery::reveal2(secret, clock, &mut lottery, ctx);
    ts::return_shared(lottery);

    scenario.next_tx(@0x0);
    let ctx = scenario.ctx();
    random::create_for_testing(ctx);
    scenario

}

fun redeem_test(sender: address, clock: &Clock, mut scenario: Scenario){
    scenario.next_tx(sender);
    let lottery = scenario.take_shared<Lottery<IOTA>>();
    let ctx = scenario.ctx();
    lottery::redeem(clock, lottery, ctx);
    scenario.end();
}

fun win_test(mut scenario: Scenario){
    scenario.next_tx(PLAYER1);
    let lottery = scenario.take_shared<Lottery<IOTA>>();
    let random = scenario.take_shared<random::Random>();
    let ctx = scenario.ctx();
    lottery::win(&random, lottery, ctx);
    ts::return_shared(random);
    scenario.end();
}

fun increment(clock: &mut Clock, min: u64){
    clock.increment_for_testing(min * 60000);
}

#[test]
public fun intended_way_win(){
    let ( scenario, clock) = join1_test();
    let hash = keccak256(&b"world");
    let scenario = join2_test(1000, hash, &clock, scenario);
    let scenario = reveal1_test(PLAYER1, b"hello", &clock, scenario);
    let scenario = reveal2_test(PLAYER2, b"world", &clock, scenario);
    clock.destroy_for_testing();
    win_test(scenario);
}

#[test]
public fun intended_way_redeem_palyer1(){
    let ( scenario, mut clock) = join1_test();
    increment(&mut clock, 5);
    let hash = keccak256(&b"world");
    let scenario = join2_test(1000, hash, &clock, scenario);
    let scenario = reveal1_test(PLAYER1, b"hello", &clock, scenario);
    increment(&mut clock, 11);
    redeem_test(PLAYER1, &clock, scenario);
    clock.destroy_for_testing();
}

#[test]
public fun intended_way_redeem_palyer2(){
    let ( scenario, mut clock) = join1_test();
    increment(&mut clock, 5);
    let hash = keccak256(&b"world");
    let scenario = join2_test(1000, hash, &clock, scenario);
    increment(&mut clock, 11);
    redeem_test(PLAYER2, &clock, scenario);
    clock.destroy_for_testing();
}

#[test]
public fun intended_way_redeem_commit(){
    let ( scenario, mut clock) = join1_test();
    increment(&mut clock, 11);
    redeem_commit_test(PLAYER1, &clock, scenario);
    clock.destroy_for_testing();
}

#[test, expected_failure(abort_code = lottery::EWrongAmount)]
public fun wrong_amount_join2(){
    let ( scenario, clock) = join1_test();
    let hash = keccak256(&b"world");
    let scenario = join2_test(500, hash, &clock, scenario);
    clock.destroy_for_testing();
    scenario.end();
}

#[test, expected_failure(abort_code = lottery::ETimeExpired)]
public fun time_expired_join2(){
    let ( scenario, mut clock) = join1_test();
    increment(&mut clock, 11);
    let hash = keccak256(&b"world");
    let scenario = join2_test(1000, hash, &clock, scenario);
    clock.destroy_for_testing();
    scenario.end();
}

#[test, expected_failure(abort_code = lottery::ETimeNotExpired)]
public fun time_not_expired_redeem_commit(){
    let ( scenario, mut clock) = join1_test();
    increment(&mut clock, 5);
    redeem_commit_test(PLAYER1, &clock, scenario);
    clock.destroy_for_testing();
}

#[test, expected_failure(abort_code = lottery::EPermissionDenied)]
public fun not_palyer1_redeem_commit(){
    let ( scenario, mut clock) = join1_test();
    increment(&mut clock, 11);
    redeem_commit_test(USER, &clock, scenario);
    clock.destroy_for_testing();
}

#[test, expected_failure(abort_code = lottery::EWrongSecret)]
public fun incorrect_secret_reveal1(){
    let ( scenario, mut clock) = join1_test();
    increment(&mut clock, 5);
    let hash = keccak256(&b"world");
    let scenario = join2_test(1000, hash, &clock, scenario);
    let scenario = reveal1_test(PLAYER1, b"hell", &clock, scenario);
    clock.destroy_for_testing();
    scenario.end();
}

#[test, expected_failure(abort_code = lottery::ETimeExpired)]
public fun time_expired_reveal1(){
    let ( scenario, mut clock) = join1_test();
    let hash = keccak256(&b"world");
    let scenario = join2_test(1000, hash, &clock, scenario);
    increment(&mut clock, 11);
    let scenario = reveal1_test(PLAYER1, b"hello", &clock, scenario);
    clock.destroy_for_testing();
    scenario.end();
}

#[test, expected_failure(abort_code = lottery::EWrongSecret)]
public fun incorrect_secret_reveal2(){
    let ( scenario, mut clock) = join1_test();
    increment(&mut clock, 5);
    let hash = keccak256(&b"world");
    let scenario = join2_test(1000, hash, &clock, scenario);
    let scenario = reveal1_test(PLAYER1, b"hello", &clock, scenario);
    let scenario = reveal2_test(PLAYER2, b"word", &clock, scenario);
    clock.destroy_for_testing();
    scenario.end();
}

#[test, expected_failure(abort_code = lottery::ETimeExpired)]
public fun time_expired_reveal2(){
    let ( scenario, mut clock) = join1_test();
    let hash = keccak256(&b"world");
    let scenario = join2_test(1000, hash, &clock, scenario);
    let scenario = reveal1_test(PLAYER1, b"hello", &clock, scenario);
    increment(&mut clock, 11);
    let scenario = reveal2_test(PLAYER2, b"world", &clock, scenario);
    clock.destroy_for_testing();
    scenario.end();
}

#[test, expected_failure(abort_code = lottery::ETimeNotExpired)]
public fun time_not_expired_redeem_palyer1(){
    let ( scenario, clock) = join1_test();
    let hash = keccak256(&b"world");
    let scenario = join2_test(1000, hash, &clock, scenario);
    let scenario = reveal1_test(PLAYER1, b"hello", &clock, scenario);
    redeem_test(PLAYER1, &clock, scenario);
    clock.destroy_for_testing();
}

#[test, expected_failure(abort_code = lottery::ETimeNotExpired)]
public fun sender_not_palyer1_redeem(){
    let ( scenario, mut clock) = join1_test();
    let hash = keccak256(&b"world");
    let scenario = join2_test(1000, hash, &clock, scenario);
    let scenario = reveal1_test(PLAYER1, b"hello", &clock, scenario);
    increment(&mut clock, 11);
    redeem_test(PLAYER2, &clock, scenario);
    clock.destroy_for_testing();
}

#[test, expected_failure(abort_code = lottery::ETimeNotExpired)]
public fun time_not_expired_redeem_palyer2(){
    let ( scenario, mut clock) = join1_test();
    let hash = keccak256(&b"world");
    let scenario = join2_test(1000, hash, &clock, scenario);
    increment(&mut clock, 5);
    redeem_test(PLAYER2, &clock, scenario);
    clock.destroy_for_testing();
}

#[test, expected_failure(abort_code = lottery::ETimeNotExpired)]
public fun sender_not_palyer2_redeem(){
    let ( scenario, mut clock) = join1_test();
    let hash = keccak256(&b"world");
    let scenario = join2_test(1000, hash, &clock, scenario);
    increment(&mut clock, 11);
    redeem_test(PLAYER1, &clock, scenario);
    clock.destroy_for_testing();
}