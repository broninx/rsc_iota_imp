module bet::bet;

  use iota::coin;
  use iota::clock::{Clock, timestamp_ms};
  use iota::balance::Balance;

  const EOverTimeLimit: u64 = 0;
  const EWinnerNotPlayer: u64  = 1;
  const EPermissionDenied: u64  = 2;
  const ETimeIsNotFinish: u64 = 3;
    
  public struct Oracle has key, store {
    id: UID,
    addr: address,
    deadline: u64
  }

  public struct Bet<phantom T> has key {
    id: UID,
    amount: Balance<T>,
    player1: address,
    player2: address,
    oracle: address,
    timeout: u64
  }

  fun init(ctx: &mut TxContext){
    let oracle = Oracle {
      id: object::new(ctx),
      addr: ctx.sender(),
      deadline: 0 // 10 min
    };
    transfer::share_object(oracle);
  }

  public fun initialize(deadline: u64, oracle: &mut Oracle, ctx: &mut TxContext){
    assert!(ctx.sender() == oracle.addr, EPermissionDenied);
    oracle.deadline = deadline;
  }

  public fun join<T> (
    clock: &Clock, 
    wager: coin::Coin<T>,
    p1: address, 
    p2: address, 
    oracle: &Oracle,
    ctx: &mut TxContext
    ){
        let wager = wager.into_balance();
        let bet = Bet<T>{
          id: object::new(ctx),
          amount: wager,
          player1: p1,
          player2: p2,
          oracle: oracle.addr,
          timeout: clock.timestamp_ms() + oracle.deadline 
        };
        transfer::share_object(bet);
    }
  
  public fun win<T> (bet: Bet<T>, winner: address, clock: &Clock, ctx: &mut TxContext) {
    assert!(clock.timestamp_ms() < bet.timeout, EOverTimeLimit);
    assert!(winner == bet.player1 || winner == bet.player2, EWinnerNotPlayer);
    assert!(bet.oracle == ctx.sender(), EPermissionDenied);

    let Bet {id: id,amount: wager, player1: _, player2: _,oracle: _, timeout: _} = bet;
    let wager = coin::from_balance(wager, ctx);
    transfer::public_transfer(wager, winner);

    id.delete();
  }
  
  public fun timeout<T> (bet: Bet<T>, clock: &Clock, ctx: &mut TxContext){
    assert!(clock.timestamp_ms() > bet.timeout, ETimeIsNotFinish);
    let Bet {id: id, amount:mut wager, player1: p1, player2: p2,oracle: _, timeout: _} = bet;
    id.delete();
    let amount = wager.value();

    let wager1 = wager.split(amount /2);
    
    transfer::public_transfer(coin::from_balance(wager, ctx), p1);
    transfer::public_transfer(coin::from_balance(wager1, ctx), p2);
  }

#[test_only]

public fun init_test(ctx: &mut TxContext){
    let oracle = Oracle {
      id: object::new(ctx),
      addr: tx_context::sender(ctx),
      deadline: 600000 // 10 min
    };
    transfer::share_object(oracle);
}

