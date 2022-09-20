-module(worker_two).

-export([start_worker/2, generate_random/2, countZeros/2, returnString/3, runLoop/1, listenForServer/2]).
-define(WORKER_PID_NAME, workerNodeTwo).
start_worker(ServerPID, ServerNode) ->
  register(?WORKER_PID_NAME, spawn(worker_two, listenForServer, [ServerPID, ServerNode])),

% Initially send a ping to server indicating worker is available to mine coins
{ServerPID, ServerNode} ! {ready_to_mine, ?WORKER_PID_NAME, node()}.

 % register(workerNode, Pid).
 % io:fwrite("Master's PID is :: ~p ~n", [pid_to_list(global:whereis_name(ServerPID))]),
%  WorkerPID  = spawn(worker, listenForServer, [ServerPID, ServerNode]),
%  yes = global:register_name(WorkerPID, WorkerPID).

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

returnString(ServerPIDName, ServerNode, ZeroCount)->
  RandomStringLength = 8,
  [RandomString, RandomHash] = generate_random(RandomStringLength, "ABCDEFGHIJKLMOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890"),
  CheckTrue = countZeros(RandomHash, ZeroCount),
  case CheckTrue of
    found ->
      {ServerPIDName, ServerNode} ! {coinFound, string:concat(RandomString, string:concat(" ",RandomHash)), ?WORKER_PID_NAME, node(), ZeroCount},
    listenForServer(ServerPIDName, ServerNode);
    notFound ->
      %io:fwrite(" Not found in PID : ~p~n",[pid_to_list(self())]),
      returnString(ServerPIDName,ServerNode, ZeroCount)
  end.

runLoop(Key) ->
  lists:foreach(
    fun(_) ->
      returnString(Key,8,3)
    end, lists:seq(1, 30)).


listenForServer(MasterPIDName, MasterNode) ->
  %returnString(MasterNode, ZeroCount),

  receive
    {startMining, ZeroCount, MasterPIDName, MasterNode} ->
      io:format("Start to mine called ~n"),
      returnString(MasterPIDName, MasterNode , ZeroCount),
      listenForServer(MasterPIDName, MasterNode)
  end.
