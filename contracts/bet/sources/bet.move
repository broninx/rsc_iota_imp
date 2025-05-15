module bet::bet;

  use iota::coin;
  use iota::clock::{Clock, timestamp_ms};

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
      amount: coin::Coin<T>,
      player1: address,
      player2: address,
      oracle: address,
      timeout: u64
    }

      fun init (ctx: &mut TxContext){
      let oracle = Oracle {
        id: object::new(ctx),
        addr: tx_context::sender(ctx),
        deadline: 600000 // 10 min
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
          oracle: oracle.addr,
          timeout: timestamp_ms(clock) + oracle.deadline 
        };
        transfer::share_object(bet);
    }
  
  public fun win<T> (bet: Bet<T>, winner: address, clock: &Clock, ctx: &mut TxContext) {
    assert!(timestamp_ms(clock) < bet.timeout, EOverTimeLimit);
    assert!(winner == bet.player1 || winner == bet.player2, EWinnerNotPlayer);
    assert!(bet.oracle == ctx.sender(), EPermissionDenied);

    let Bet {id: id,amount: wager, player1: _, player2: _,oracle: _, timeout: _} = bet;
    transfer::public_transfer(wager, winner);


    object::delete(id);
    }
  
  public fun timeout<T> (bet: Bet<T>, clock: &Clock, ctx: &mut TxContext){
    assert!(clock.timestamp_ms() > bet.timeout, ETimeIsNotFinish);
    let Bet {id: id,amount: wager, player1: p1, player2: p2,oracle: _, timeout: _} = bet;
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

public fun create_oracle(addr: address, deadline: u64,ctx: &mut TxContext): Oracle{
  Oracle {id: object::new(ctx), addr: addr,deadline: deadline}
}

public fun transfer_share_object(obj: Oracle){
  transfer::share_object(obj);
}

