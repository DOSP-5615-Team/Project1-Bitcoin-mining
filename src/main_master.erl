-module(main_master).

-export([ start_master/1, generate_random/2, countZeros/2, returnString/2, runLoop/1, listenForWorkers/1]).


%start_master() ->
%   register(masterNode, spawn(server_two, listenForWorkers, [])),
%  io:format("This is ~p",[pid_to_list(whereis(masterNode))]).

start_master(ZeroCount) ->
  register(masterNode, spawn( main_master, listenForWorkers, [ZeroCount])),
{masterNode, node()} ! {ready_to_mine_server, masterNode},
  lists:foreach(
    fun(_) ->
      spawn(main_master, returnString,[ZeroCount, 10])
    end, lists:seq(1, 3)).



 % Pid = spawn(main_master, listenForWorkers, [ZeroCount]),
 % io:fwrite("PID of me: ~p~n",[pid_to_list(Pid)]),
 % yes = global:register_name('masterPID', Pid).


generate_random(Length, AllowedChars) ->
  MaxLength = length(AllowedChars),
  RandomString = string:concat("vemetlapalli;",lists:foldl(
    fun(_, Acc) -> [lists:nth(crypto:rand_uniform(1, MaxLength), AllowedChars)] ++ Acc end,
    [], lists:seq(1, Length))
  ),
  [RandomString, io_lib:format("~64.16.0b", [binary:decode_unsigned(crypto:hash(sha256, RandomString))])].

countZeros([_First | _Rest],0)->
  found;
countZeros([First | Rest],Zeros) when Zeros > 0 ->
  %io:format("List is :: ~w ~n" , [[First | Rest]]),
  %io:format("First is :: ~w ~n" , [First]),
  %io:format("LAst is :: ~w ~n" , [Rest]),
  % Comparing with 0 (whose binary value is 48)
  if
    First == 48 ->
      countZeros(Rest, Zeros-1);
    true -> notFound
  end
.

returnString( ZeroCount, 0)->

  %io:format("Master child process stopped mining ~n"),
  exit("normal");
returnString( ZeroCount, CoinsToBeMined)->
  RandomStringLength = 8,
  [RandomString, RandomHash] = generate_random(RandomStringLength, "ABCDEFGHIJKLMOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890"),
  CheckTrue = countZeros(RandomHash, ZeroCount),
  case CheckTrue of
    found ->
    %  io:format("Format done"),
      io:format("~s", [string:concat(RandomString, string:concat(" ",RandomHash))]),
      io:format("PID : ~p ~n", [masterNode]),
    %  {masterNode, node()} ! {coinFound_in_Master, string:concat(RandomString, string:concat(" ",RandomHash))};
     % exit(normal);
     % listenForWorkers(ZeroCount);
      returnString( ZeroCount, CoinsToBeMined-1);
    notFound ->
      %io:fwrite(" Not found in PID : ~p~n",[pid_to_list(self())]),
      returnString( ZeroCount, CoinsToBeMined)
  end.

runLoop(Key) ->
  lists:foreach(
    fun(_) ->
      returnString(Key, 5)
    end, lists:seq(1, 30)).

%listenForWorkers(ZeroCount)->
%  exit(normal);
listenForWorkers(ZeroCount)->
  %returnString(ZeroCount),
 % whereis(masterNode) ! {ready_to_mine_server, whereis(masterNode)},
  receive
    {ready_to_mine, WorkerPID, WorkerNode} ->
      io:format("Worker ready to mine coins ~n"),
    %  io:fwrite(" PID of wo : ~p  and node is ~p ~n",[pid_to_list(whereis(WorkerPID)), WorkerNode]),
      {WorkerPID, WorkerNode} !  {startMining, ZeroCount, masterNode, node()},
    listenForWorkers(ZeroCount);

   % {coinFound_in_Master, FoundString } ->
    %  io:format("Reached the server"),
    %  io:format("~s",[FoundString]),
    %  io:fwrite("PID : ~p~n",[masterNode]),
    %listenForWorkers(ZeroCount);

    { coinFound, StringFound, SenderPIDName, SenderNode , ZeroCount } ->
     % io:format("Coin found by worker"),
      io:format("~s",[StringFound]),
       io:fwrite("PID : ~p~n",[SenderPIDName]),
     % {SenderPIDName, SenderNode} ! {startMining, ZeroCount , masterNode, node()},
      listenForWorkers(ZeroCount)

     % {ready_to_mine_server, MasterPIDName} -> io:format("Server started mining")
       % io:fwrite(" Master is mining, Master PID : ~p~n",[pid_to_list(whereis(MasterPIDName))]),

  end
.



%1. timers
%2. Server should start mining incase of no workers
%3. Worker loop needed