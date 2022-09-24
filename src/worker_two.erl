-module(worker_two).

-export([start_worker/2, generate_random/2, countZeros/2, returnString/4, listenForServer/2]).
-define(WORKER_PID_NAME, workerNodeTwo).
start_worker(ServerPID, ServerNode) ->
  register(?WORKER_PID_NAME, spawn(worker_two, listenForServer, [ServerPID, ServerNode])),

% Initially send a ping to server indicating worker is available to mine coins
{ServerPID, ServerNode} ! {ready_to_mine, ?WORKER_PID_NAME, node()}.

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
    First == 48 ->
      countZeros(Rest, Zeros-1);
    true -> notFound
  end
.

returnString(_ServerPIDName, _ServerNode, _ZeroCount, 0)->
  %io:format("Worker child process stopped mining ~n"),
  exit("normal");

returnString(ServerPIDName, ServerNode, ZeroCount, N)->
  RandomStringLength = 8,
  [RandomString, RandomHash] = generate_random(RandomStringLength, "ABCDEFGHIJKLMOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890"),
  CheckTrue = countZeros(RandomHash, ZeroCount),
  case CheckTrue of
    found ->
      {ServerPIDName, ServerNode} ! {coinFound, string:concat(RandomString, string:concat(" ",RandomHash)), ?WORKER_PID_NAME, node(), ZeroCount},
      returnString(ServerPIDName, ServerNode, ZeroCount, N-1);
    notFound ->
      returnString(ServerPIDName,ServerNode, ZeroCount, N)
  end.


listenForServer(MasterPIDName, MasterNode) ->

  receive
    {startMining, ZeroCount, MasterPIDName, MasterNode} ->
      io:format("Start to mine called ~n"),
      lists:foreach(

        fun(_) ->
          spawn(worker_two, returnString,[MasterPIDName, MasterNode , ZeroCount, 2])
        end, lists:seq(1, erlang:system_info(logical_processors_available))),
      listenForServer(MasterPIDName, MasterNode)
  end.
