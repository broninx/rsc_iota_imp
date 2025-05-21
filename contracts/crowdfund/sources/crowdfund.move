module crowdfund::crowdfund;

use iota::iota::{Self, IOTA};
use iota::clock::Clock;
use iota::vec_map::{Self, VecMap};
use iota::coin::{Self, Coin};

const EPermissionDenied: u64 = 0;
const EJustInit: u64 = 1;
const ETimeFinished: u64 = 2;
const ETimeNotFinished: u64 = 4;
const EGoalNotAchived: u64 = 5;
const ENotInitialized: u64 = 6;
const EGoalAchived: u64 = 7;
const ENotDonor: u64 = 8;

public struct Crowdfund has key {
    id: UID,
    admin: address,
    recipient: address,
    donors: VecMap<address, Coin<IOTA>>,
    goal: u64, // of IOTA coin
    amount: u64, // of IOTA coin
    deadline: u64, // in ms
    initialized: bool
}

public fun destroy(self: Crowdfund){
    let Crowdfund {
        id: id,
        admin: _,
        recipient: _,
        donors: donors,
        goal: _,
        amount: _,
        deadline: _,
        initialized:_ 
    } = self;
    object::delete(id);
    donors.destroy_empty();
}
fun init(ctx: &mut TxContext){
    let donors = vec_map::empty<address, Coin<IOTA>>();
    let crowdfund = Crowdfund {
        id: object::new(ctx),
        admin: ctx.sender(),
        recipient: ctx.sender(),
        donors: donors,
        goal: 0,
        amount: 0,
        deadline: 0,
        initialized: false
    };
    transfer::share_object(crowdfund);
}

//deadline field must be in hours
public fun initialize(recipient: address, goal: u64, deadline: u64,crowdfund: &mut Crowdfund, clock: &Clock, ctx: &mut TxContext){
    assert!(ctx.sender() == crowdfund.admin, EPermissionDenied);
    assert!(!crowdfund.initialized, EJustInit); 

    crowdfund.recipient = recipient;
    crowdfund.goal = goal;
    let deadline= deadline * 3600000; 
    crowdfund.deadline = clock.timestamp_ms() + deadline;
    crowdfund.initialized = true;
}

public fun donate(donation: Coin<IOTA>, crowdfund: &mut Crowdfund, clock: &Clock, ctx: &mut TxContext){
    assert!(clock.timestamp_ms() <= crowdfund.deadline, ETimeFinished);
    assert!(crowdfund.initialized, ENotInitialized);

    crowdfund.amount = crowdfund.amount + donation.value();
    if (crowdfund.donors.contains(&ctx.sender())){
        let donation_just_sended = crowdfund.donors.get_mut(&ctx.sender());
        donation_just_sended.join(donation);
    } else {
        crowdfund.donors.insert(ctx.sender(), donation);
    };
}

public fun withdraw(mut crowdfund: Crowdfund, clock: &Clock, ctx: &mut TxContext){
    assert!(crowdfund.recipient == ctx.sender(), EPermissionDenied);
    assert!(clock.timestamp_ms() >= crowdfund.deadline, ETimeNotFinished);
    assert!(crowdfund.amount >= crowdfund.goal, EGoalNotAchived);

    let mut donations = coin::zero<IOTA>(ctx);
    while (!crowdfund.donors.is_empty()) {
        let (_, donation) = crowdfund.donors.pop();
        donations.join(donation);
    };
    iota::transfer(donations, crowdfund.recipient);
    crowdfund.destroy();
}


public fun reclaim(mut crowdfund: Crowdfund, clock: &Clock, ctx: &mut TxContext){
    assert!(clock.timestamp_ms() >= crowdfund.deadline, ETimeNotFinished);
    assert!(crowdfund.amount < crowdfund.goal, EGoalAchived);
    assert!(crowdfund.donors.contains(&ctx.sender()), ENotDonor);

    let (donor, donation) = crowdfund.donors.remove(&ctx.sender());
    iota::transfer(donation, donor);
    if (crowdfund.donors.is_empty()){
        crowdfund.destroy();
    } else {
        transfer::share_object(crowdfund);
    }
}

#[test_only]
public fun init_test(ctx: &mut TxContext){
    let donors = vec_map::empty<address, Coin<IOTA>>();
    let crowdfund = Crowdfund {
        id: object::new(ctx),
        admin: ctx.sender(),
        recipient: ctx.sender(),
        donors: donors,
        goal: 0,
        amount: 0,
        deadline: 0,
        initialized: false
    };
    transfer::share_object(crowdfund);
}
