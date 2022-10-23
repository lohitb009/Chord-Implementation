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
-export([calculator/2, startCalc/2]).

startCalc(Hops, Queries_Completed) ->
  ActorPid = spawn_link(?MODULE, calculator, [Hops, Queries_Completed]),
  %%% io:format("ActorPID Started At : ~p~n",[ActorPid]),
  ActorPid.

calculator(Hops, Queries_Completed) ->
  receive
    {query_complete, Hops_Taken} ->
      Average_Hops = (Hops+Hops_Taken) / (Queries_Completed+1),
      io:format("hops Average: ~p Total received : ~p Hops now: ~p ~n",[Average_Hops, Queries_Completed, Hops_Taken]),
      calculator(Hops+Hops_Taken, Queries_Completed+1)
  end.

