module rsc_iota_imp::bet;

  use iota::coin;
  use iota::clock::{Self, Clock, timestamp_ms};

  const EOverTimeLimit: u64 = 0;
  const EWinnerNotPlayer: u64  = 1;
  const EPermissionDenied: u64  = 2;
  const ETimeIsNotFinish: u64 = 3;
  const EEmptyInventory: u64 = 4;

  // unit of measurement in milliseconds
    
  public struct Oracle has key, store {
    id: UID,
    addr: address,
    deadline: u64
  }
  public struct Bet<phantom T> has key {
      id: UID,
      amount: coin::Coin<T>,
      player1: address,
      player2: address,
      startcount: u64
    }

  public entry fun initialize (o: address, dl: u64, ctx: &mut TxContext){
      let oracle = Oracle {
        id: object::new(ctx),
        addr: o,
        deadline: dl
      };
      transfer::share_object(oracle);
  }

  public fun join<T> (
    clock: &Clock, 
    wager: coin::Coin<T>,
    p1: address, 
    p2: address, 
    oracle: &Oracle,
    ctx: &mut TxContext
    ){
      let bet = Bet<T>{
          id: object::new(ctx),
          amount: wager,
          player1: p1,
          player2: p2,
          startcount: timestamp_ms(clock) + oracle.deadline
        };
        transfer::share_object(bet);
    }
  
  public fun win<T> (bet: Bet<T>, oracle: &Oracle, winner: address, clock: &Clock, ctx: &mut TxContext) {
    assert!(timestamp_ms(clock) < bet.startcount + oracle.deadline, EOverTimeLimit);
    assert!(winner == bet.player1 || winner == bet.player2, EWinnerNotPlayer);
    assert!(oracle.addr == ctx.sender(), EPermissionDenied);

    let Bet {id: id,amount: wager, player1: _, player2: _, startcount: _} = bet;
    transfer::public_transfer(wager, winner);


    object::delete(id);
    }
  
  public fun timeout<T> (bet: Bet<T>, oracle: &Oracle, clock: &Clock, ctx: &mut TxContext){
    assert!(clock.timestamp_ms() > (bet.startcount + oracle.deadline), ETimeIsNotFinish);
    let Bet {id: id,amount: wager, player1: p1, player2: p2, startcount: _} = bet;
    object::delete(id);
    let amount = wager.value();
    let mut wager = wager;

    let wager1 = wager.split(amount / 2, ctx);
    transfer::public_transfer(wager, p1);
    transfer::public_transfer(wager1, p2);
  }


#[test_only]
public fun create_oracle(id_oracle: address, dl: u64, ctx: &mut TxContext): Oracle{ 
  Oracle {
    id : object::new(ctx),
    addr: id_oracle,
    deadline: dl 
  }
}

#[test]
public fun bet_test(){
  use iota::test_scenario;
  use iota::iota::IOTA;
  
  let admin: address = @0xFFFF;
  let player1: address = @0xCAFE;
  let player2: address = @0xFACE;
  let oracle: address = @0xADD;

  let mut scenario = test_scenario::begin(oracle);
  {
    initialize(oracle, 200000, test_scenario::ctx(&mut scenario));
  };
  test_scenario::next_tx(&mut scenario, player1);
  {
    assert!(test_scenario::has_most_recent_shared<Oracle>(), EEmptyInventory);
    let ctx = test_scenario::ctx(&mut scenario);
    let oracle = create_oracle(oracle, 200000, ctx);
    let cl = clock::create_for_testing(ctx);
    let coin = coin::mint_for_testing<IOTA>(10, ctx);
    join(& cl, 
    coin,
    player1, 
    player2, 
    & oracle, 
    ctx);
    //this assert need the finish of this transaction.
    //At the start of the next transaction become possible check this out
    //assert!(test_scenario::has_most_recent_shared<Bet<IOTA>>(), EEmptyInventory);
    cl.destroy_for_testing();
    let Oracle { id: id_oracle, addr: _, deadline: _} = oracle;
    object::delete(id_oracle);
  };
  //test_scenario::next_tx(&mut scenario, oracle);
  test_scenario::end( scenario);
  //do some test to win function 
}
