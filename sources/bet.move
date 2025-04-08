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
    ctx: &mut TxContext
    ){
      let bet = Bet<T>{
          id: object::new(ctx),
          amount: wager,
          player1: p1,
          player2: p2,
          startcount: timestamp_ms(clock) 
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
public fun destroy(self:Oracle){
  let Oracle {id: id, addr: _, deadline: _} = self;
  object::delete(id);
}

public fun deadline(self:&Oracle): u64{
  self.deadline
}