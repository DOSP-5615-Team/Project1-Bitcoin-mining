-module(main_master).

-export([ start_master/1, generate_random/2, countZeros/2, returnString/2, listenForWorkers/1]).

start_master(ZeroCount) ->
  {_,_} = statistics(runtime),
  {_,_} = statistics(wall_clock),
  register(masterNode, spawn( main_master, listenForWorkers, [ZeroCount])),
{masterNode, node()} ! {ready_to_mine_server, masterNode},
  Logical_Cores = erlang:system_info(logical_processors_available),
  lists:foreach(
    fun(_) ->
      spawn(main_master, returnString,[ZeroCount, 2])
    end, lists:seq(1, Logical_Cores)).

generate_random(Length, AllowedChars) ->
  MaxLength = length(AllowedChars),
  RandomString = string:concat("vemetlapalli;",lists:foldl(
    fun(_, Acc) -> [lists:nth(crypto:rand_uniform(1, MaxLength), AllowedChars)] ++ Acc end,
    [], lists:seq(1, Length))
  ),
  [RandomString, io_lib:format("~64.16.0b", [binary:decode_unsigned(crypto:hash(sha256, RandomString))])].

countZeros([_First | _Rest],0)->
  found;
countZeros([First | Rest],1)->
  [Next | _] = Rest,
  if
    First == 48  andalso Next /= 48 ->
      countZeros(Rest, 0);
    true -> notFound
  end
;
countZeros([First | Rest],Zeros) when Zeros > 0 ->
  % Comparing with 0 (whose binary value is 48)
  if
    First == 48  ->
      countZeros(Rest, Zeros-1);
    true -> notFound
  end
.

returnString( _, 0)->
  exit("normal");

returnString( ZeroCount, CoinsToBeMined)->
  RandomStringLength = 8,
  [RandomString, RandomHash] = generate_random(RandomStringLength, "ABCDEFGHIJKLMOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890"),
  CheckTrue = countZeros(RandomHash, ZeroCount),
  case CheckTrue of
    found ->
      io:format("~s", [string:concat(RandomString, string:concat(" ",RandomHash))]),
      io:format("PID : ~p ~n", [masterNode]),
      returnString( ZeroCount, CoinsToBeMined-1);
    notFound ->
      returnString( ZeroCount, CoinsToBeMined)
  end.

listenForWorkers(ZeroCount)->
  receive
    {ready_to_mine, WorkerPID, WorkerNode} ->
      io:format("Worker ready to mine coins ~n"),
      {WorkerPID, WorkerNode} !  {startMining, ZeroCount, masterNode, node()},
    listenForWorkers(ZeroCount);

    { coinFound, StringFound, SenderPIDName, _SenderNode , ZeroCount } ->
      io:format("~s",[StringFound]),
       io:fwrite("PID : ~p~n",[SenderPIDName]),
      listenForWorkers(ZeroCount)

  after 25000 ->
    {_,CPU_time} = statistics(runtime),
    {_,Run_time} = statistics(wall_clock),
    timer:sleep(5000),
    T = CPU_time/ 1000,
    T2 = Run_time / 1000,
    T3 = T/ T2,
    io:format("CPU time: ~p seconds\n", [T]),
    io:format("Real time: ~p seconds\n", [T2]),
    io:format("Ratio is ~p \n", [T3]),
    exit(normal)

end
.
