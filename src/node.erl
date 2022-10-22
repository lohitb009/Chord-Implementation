%%%-------------------------------------------------------------------
%%% @author User
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 20. Oct 2022 2:17 PM
%%%-------------------------------------------------------------------
-module(node).
-author("User").

%% API
-export([startLink/4, main_loop/4]).

startLink(ChordId, Pred, Succ, FT) ->
  ActorPid = spawn_link(?MODULE, main_loop, [ChordId, Pred, Succ, FT]),
  %%% io:format("ActorPID Started At : ~p~n",[ActorPid]),
  ActorPid.

main_loop(ChordId, Pred, Succ, FT) ->
  io:format("Node is : ~p ~n",[self()]),
%%  receive
%%    {update_ft, FT_table}
%%  end,
%%  {Succ_ID, Succ_PID} = Succ,
%%  receive
%%    {find_successor, Asker_ID, Asker_PID} ->
%%      if
%%        Asker_ID > ChordId and Asker_ID =< Succ_ID ->
%%          Asker_PID ! {succ_is, Succ};
%%        true ->
%%          Clos_prec_node = closest_preceding_node(Asker_ID),
%%          {CPN_ID, CPN_PID} = Clos_prec_node,
%%          CPN_PID ! {find_successor, Asker_ID, Asker_PID},
%%      end;
%%    stab ->
%%
%%  end,
  main_loop(ChordId, Pred, Succ, FT).
%%  done.
