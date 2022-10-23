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
-export([startLink/7, main_loop/7]).

startLink(ChordId, Pred, Succ, FT, TotalSpaces, NodeList, ArrayID) ->
  ActorPid = spawn_link(?MODULE, main_loop, [ChordId, Pred, Succ, FT, TotalSpaces, NodeList, ArrayID]),
  %%% io:format("ActorPID Started At : ~p~n",[ActorPid]),
  ActorPid.

main_loop(ChordId, Pred, Succ, FT, TotalSpaces, NodeList, ArrayID) ->
%%  io:format("Node is : ~p ~n", [self()]),
  receive
    {ok, Finger, NdList, Iter} ->
%%      io:format("Fingers is : ~p ~n", [Finger]),
%%      io:format("Iter is : ~p ~n", [Iter]),
%%      io:format("New Ndlist is : ~p ~n", [NdList]),
%%      io:format("Chord ID: ~p Array_ID: ~p ~n",[ChordId, Iter]),
      main_loop(ChordId, Pred, Succ, Finger, TotalSpaces, NdList, Iter);

%%    {update_ft, Finger, NdList, ArrayID} ->
%%      io:format("FT is : ~p ~n", [Finger]),
%%      io:format("Ndlist is : ~p ~n", [NdList]),
%%%%      io:format("FT is : ~p ~n",[Finger]),


    {send_requests, NumRequests} ->
      IDs = generate_IDs(NumRequests, TotalSpaces, []),
%%      io:format("~p keys is : ~p ~n", [self(), IDs]),
%%      io:format("Nodelist is : ~p ~n", [NodeList]),
%%      timer:sleep(5000),
      sendRequests(length(IDs), IDs, NodeList, ArrayID, FT),
      main_loop(ChordId, Pred, Succ, FT, TotalSpaces, NodeList, ArrayID);
%%      send_queries(Keys)

    {messg, Hops, Target_ID} ->
      if
        Target_ID == ChordId ->
          io:format("Reached dest, hops: ~p ~n",[Hops+1]),
          main_loop(ChordId, Pred, Succ, FT, TotalSpaces, NodeList, ArrayID);
        true ->
          Target_PID = find_target_pid(1, length(FT)+1, Target_ID, FT, lists:nth(2, lists:nth(1, FT)) ),
          Target_PID ! {messg, Hops+1, Target_ID},
          main_loop(ChordId, Pred, Succ, FT, TotalSpaces, NodeList, ArrayID)
      end

%%      if
%%        Target_ID == ChordId
%%      end
  end.

sendRequests(0, IDs, Nodelist, ArrayID, FT) ->
  done;
sendRequests(Iter, IDs, Nodelist, ArrayID, FT) ->
%%  io:format("Array ID is : ~p ~n",[ArrayID]),
%%  io:format("Actual ID for ID ~p is : ~p ~n", [lists:nth(Iter, IDs), find_succ2(lists:nth(Iter, IDs), 1, Nodelist, length(Nodelist)+1)]),
  Target_ID = find_succ2(lists:nth(Iter, IDs), 1, Nodelist, length(Nodelist)+1),
  io:format("~p Actual ID: ~p target_ID : ~p Curr_ID: ~p ~n", [self(), lists:nth(Iter, IDs), lists:nth(1, Target_ID), lists:nth(1,lists:nth(ArrayID, Nodelist)) ]),
  Target_PID = find_target_pid(1, length(FT)+1, lists:nth(1, Target_ID), FT, lists:nth(2, lists:nth(1, FT)) ),
%%  io:format("Actual ID: ~p target_ID : ~p Curr_ID: ~p target_PID: ~p ~n", [lists:nth(Iter, IDs), Target_ID, lists:nth(ArrayID, Nodelist),Target_PID ]),
  io:format("~p target_PID: ~p ~n", [self(), Target_PID ]),
  Target_PID ! {messg, 0, lists:nth(1, Target_ID)},
  sendRequests(Iter - 1, IDs, Nodelist, ArrayID, FT).
%%  find_based_on_ft(1, ).

find_target_pid(Len, Len, Target_ID, FT, Pred) ->
  Pred;
find_target_pid(Iter, Len, Target_ID, FT, Pred) ->
%%  if
%%    Pred == null -> find_target_pid(Iter, Len, Target_ID, FT, lists:nth(Iter, FT));
%%    true ->
%%  end
  Curr_ID = lists:nth(1, lists:nth(Iter, FT)),
  Curr_PID = lists:nth(2, lists:nth(Iter, FT)),
  io:format("~p Curr_ID: ~p Target_ID: ~p ~n",[self(), Curr_ID, Target_ID]),
  if
    Target_ID > Curr_ID ->
      find_target_pid(Iter+1, Len, Target_ID, FT, Curr_PID);
    Target_ID == Curr_ID ->
      Curr_PID;
    Target_ID < Curr_ID ->
      Pred;
    true -> nothing
  end.

find_succ2(Next_id, Len, NodesList, Len) ->
  lists:nth(1, NodesList);
find_succ2(Next_id, ArrayID, NodesList, Len) ->
  Curr_node = lists:nth(ArrayID, NodesList),
  Curr_ID = lists:nth(1, Curr_node),
%%  io:format("FS :: Curr_ID: ~p Next_ID: ~p ~n", [Curr_ID, Next_id]),
  if
    Curr_ID < Next_id -> find_succ2(Next_id, ArrayID + 1, NodesList, Len);
    true -> Curr_node
  end.

generate_IDs(0, TotalSpaces, Key_List) ->
  Key_List;
generate_IDs(NumRequests, TotalSpaces, Key_List) ->
  Random_ID = rand:uniform(1000000000),
  Hashed_data = crypto:hash(sha, <<Random_ID>>),
  <<Hash_to_int:160/integer>> = Hashed_data,
  Identifier = Hash_to_int rem TotalSpaces,
  generate_IDs(NumRequests - 1, TotalSpaces, Key_List ++ [Identifier]).

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

%%  done.
