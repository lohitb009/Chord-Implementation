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
-export([startLink/8, main_loop/8]).

%%CREATING ACTOR IN RING
startLink(ChordId, Pred, Succ, FT, TotalSpaces, NodeList, ArrayID, HopCalc_PID) ->
  ActorPid = spawn_link(?MODULE, main_loop, [ChordId, Pred, Succ, FT, TotalSpaces, NodeList, ArrayID, HopCalc_PID]),
  ActorPid.

main_loop(ChordId, Pred, Succ, FT, TotalSpaces, NodeList, ArrayID, HopCalc_PID) ->
  receive
  %%    POPULATING CONNECTIONS
    {ok, Finger, NdList, Iter} ->
      main_loop(ChordId, Pred, Succ, Finger, TotalSpaces, NdList, Iter, HopCalc_PID);

%%    INSTRUCTION RECEIVED TO START COMMUNICATION
    {send_requests, NumRequests} ->
      IDs = generate_IDs(NumRequests, TotalSpaces, []),
      sendRequests(length(IDs), IDs, NodeList, ArrayID, FT),
      main_loop(ChordId, Pred, Succ, FT, TotalSpaces, NodeList, ArrayID, HopCalc_PID);

%%    MESSAGE STRUCTURE FOR TRANSMISSION
    {messg, Hops, Target_ID} ->
      if
        Target_ID == ChordId ->
          HopCalc_PID ! {query_complete, Hops + 1},
          main_loop(ChordId, Pred, Succ, FT, TotalSpaces, NodeList, ArrayID, HopCalc_PID);
        true ->
          Target_PID = find_target_pid(1, length(FT) + 1, Target_ID, lists:sort(FT), lists:nth(2, lists:nth(1, FT)), NodeList),
          Target_PID ! {messg, Hops + 1, Target_ID},
          main_loop(ChordId, Pred, Succ, FT, TotalSpaces, NodeList, ArrayID, HopCalc_PID)
      end
  end.

sendRequests(0, _, _, _, _) ->
  done;
sendRequests(Iter, IDs, Nodelist, ArrayID, FT) ->
  Target_ID = find_succ2(lists:nth(Iter, IDs), 1, Nodelist, length(Nodelist) + 1),
  Target_PID = find_target_pid(1, length(FT) + 1, lists:nth(1, Target_ID), lists:sort(FT), lists:nth(2, lists:nth(1, FT)), Nodelist),
  Target_PID ! {messg, 0, lists:nth(1, Target_ID)},
  sendRequests(Iter - 1, IDs, Nodelist, ArrayID, FT).

find_target_pid(Len, Len, _, _, Pred_PID, _) ->
  Pred_PID;
find_target_pid(Iter, Len, Target_ID, FT, Pred_PID, NodeList) ->
  Curr_ID = lists:nth(1, lists:nth(Iter, FT)),
  Curr_PID = lists:nth(2, lists:nth(Iter, FT)),
  if
    Target_ID > Curr_ID ->
      find_target_pid(Iter + 1, Len, Target_ID, FT, Curr_PID, NodeList);
    Target_ID == Curr_ID ->
      Curr_PID;
    Target_ID < Curr_ID ->
      Pred_PID;
    true -> nothing
  end.

find_succ2(_, Len, NodesList, Len) ->
  lists:nth(1, NodesList);
find_succ2(Next_id, ArrayID, NodesList, Len) ->
  Curr_node = lists:nth(ArrayID, NodesList),
  Curr_ID = lists:nth(1, Curr_node),
  if
    Curr_ID < Next_id -> find_succ2(Next_id, ArrayID + 1, NodesList, Len);
    true -> Curr_node
  end.

generate_IDs(0, _, Key_List) ->
  Key_List;
generate_IDs(NumRequests, TotalSpaces, Key_List) ->
  Random_ID = rand:uniform(1000000000),
  Hashed_data = crypto:hash(sha, <<Random_ID>>),
  <<Hash_to_int:160/integer>> = Hashed_data,
  Identifier = Hash_to_int rem TotalSpaces,
  generate_IDs(NumRequests - 1, TotalSpaces, Key_List ++ [Identifier]).