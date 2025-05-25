
#[test_only]
module storage::storage_tests; 

use storage::storage::{Self, Storage};
use iota::test_scenario::{Self as ts, Scenario};

const OWNER: address = @0xCAFE;
const USER: address = @0xF4CE;

fun setup(): Scenario{
    let mut scenario = ts::begin(OWNER);
    let ctx = ts::ctx(&mut scenario);
    storage::init_test(ctx);
    scenario
}

#[test]
public fun store_bytes_sequence(){
    let mut scenario = setup();
     ts::next_tx(&mut scenario, USER);
    let mut storage = ts::take_shared<Storage>(&scenario);
    let mut bytes = vector::empty<u8>();
    bytes.push_back(72);
    bytes.push_back(105);
    storage::storeBytes(&mut storage, bytes);
    ts::return_shared(storage);
    ts::end(scenario);
}

#[test]
public fun store_string(){
    let mut scenario = setup();
     ts::next_tx(&mut scenario, USER);
    let mut storage = ts::take_shared<Storage>(&scenario);
    let string = b"Hi"; 
    storage::storeString(&mut storage, string);
    ts::return_shared(storage);
    ts::end(scenario);
}