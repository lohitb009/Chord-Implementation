%%%-------------------------------------------------------------------
%%% @author User
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 23. Oct 2022 1:42 PM
%%%-------------------------------------------------------------------
-module(hopCalculator).
-author("User").

%% API
-export([calculator/3, startCalc/3]).
-define(ReplicationFactor, 4).

startCalc(Hops, Queries_Completed, NumRequests) ->
  ActorPid = spawn_link(?MODULE, calculator, [Hops, Queries_Completed, NumRequests]),
  %%% io:format("ActorPID Started At : ~p~n",[ActorPid]),
  ActorPid.

calculator(Hops, Queries_Completed, NumRequests) ->
  receive
    {query_complete, Hops_Taken} ->
%%      To account for replication in detection of query completion
      Average_Hops = ((Hops+Hops_Taken) / (Queries_Completed+1))/(?ReplicationFactor),
      io:format("Hops Average at Current Time: ~p ~n",[Average_Hops]),
      calculator(Hops+Hops_Taken, Queries_Completed+1, NumRequests)
  end.

