-module(main).
-author("User").
-export([chord_start/2, find_succ/3]).

-define(Mult_factor, 2).

totalSpaces(Power, TotalNodes) ->
  if
    Power < TotalNodes -> totalSpaces(Power * 2, TotalNodes);
    true -> Power
  end.


chord_start(TotalNodes, NumRequests) ->

  TotalSpaces = totalSpaces(1, TotalNodes),
%%  io:format("TotalSpaces is ~p ~n ", [TotalSpaces]),
  Nodes_list = add_nodes(TotalNodes, round(TotalSpaces), no_peers, [], []),
  io:format("Full List is ~p ~n ", [Nodes_list]),
  Nodes_list_wc = gen_ft(1, TotalNodes+1, Nodes_list, []),
%%  send ft to all nodes
  io:format("Full Connx List is ~p ~n ", [Nodes_list_wc]),
  send_ft(1, Nodes_list_wc, length(Nodes_list_wc)+1, NumRequests, Nodes_list),
  send_ft2(1, Nodes_list_wc, length(Nodes_list_wc)+1, NumRequests, Nodes_list).

%%  io:format("Full List is ~p ~n ", [Nodes_list]),


send_ft(Len, Nodes_list_wc, Len, NumRequests, Nodes_list) ->
  io:format("Done sending ~n");
send_ft(Iter, Nodes_list_wc, Len, NumRequests, Nodes_list) ->
  Curr_node = lists:nth(Iter, Nodes_list_wc),
  Curr_node_pid = lists:nth(2, Curr_node),
%%  io:format("main: Nodelist : ~p ~n ", [Nodes_list]),
%%  {update_ft, Finger, NdList, ArrayID}
  Finger = lists:nth(3, Curr_node),

%%  io:format("Finger: ~p Nodes_list: ~p Iter: ~p ~n ", [Finger, Nodes_list, Iter]),
%%  Curr_node_pid ! {update_ft, Finger, Nodes_list, Iter},
%%  Curr_node_pid ! {update_ft, "ABC", "XYZ", "ASD"},

  Curr_node_pid ! {ok, Finger, Nodes_list, Iter},
%%  timer:sleep(5000),
%%  Curr_node_pid ! {send_requests, NumRequests},
%%  io:format("Sent to ~p ~n ", [Curr_node_pid]),
  send_ft(Iter+1, Nodes_list_wc, Len, NumRequests, Nodes_list).

send_ft2(Len, Nodes_list_wc, Len, NumRequests, Nodes_list) ->
  io:format("Done sending ~n");
send_ft2(Iter, Nodes_list_wc, Len, NumRequests, Nodes_list) ->
  Curr_node = lists:nth(Iter, Nodes_list_wc),
  Curr_node_pid = lists:nth(2, Curr_node),
  Finger = lists:nth(3, Curr_node),
  Curr_node_pid ! {send_requests, NumRequests},
  send_ft2(Iter+1, Nodes_list_wc, Len, NumRequests, Nodes_list).

add_nodes(0, _, _, Nodes_list, _) ->
  lists:sort(Nodes_list);
add_nodes(TotalNodes, TotalSpaces, no_peers, Nodes_list, Occupied_Ids) ->
  Random_ID = rand:uniform(1000000000),
  Hashed_data = crypto:hash(sha, <<Random_ID>>),
  <<Hash_to_int:160/integer>> = Hashed_data,
  Identifier = Hash_to_int rem TotalSpaces,

  NodePID = node:startLink(Identifier, null, null, null, TotalSpaces, null, null),

  add_nodes(TotalNodes - 1, TotalSpaces, {Identifier, self()}, Nodes_list ++ [[Identifier, NodePID]], Occupied_Ids ++ [Identifier]);

add_nodes(TotalNodes, TotalSpaces, Peer = {Peer_ID, Peer_PID}, Nodes_list, Occupied_Ids) ->
  Random_ID = rand:uniform(1000000000),
  Hashed_data = crypto:hash(sha, <<Random_ID>>),
  <<Hash_to_int:160/integer>> = Hashed_data,
  Identifier = Hash_to_int rem TotalSpaces,

  NodePID = node:startLink(Identifier, null, {Identifier, self()}, null, TotalSpaces, null, null),
  Already_occupied_id = lists:member(Identifier, Occupied_Ids),
  if
    Already_occupied_id ->
%%      io:format("~p is Already occupied id in ~p ~n", [Identifier, Occupied_Ids]),
      add_nodes(TotalNodes, TotalSpaces, Peer, Nodes_list, Occupied_Ids);
    true ->
%%      io:format("~p is Not occupied id in ~p ~n", [Identifier, Occupied_Ids]),
      add_nodes(TotalNodes - 1, TotalSpaces, Peer, Nodes_list ++ [[Identifier, NodePID]], Occupied_Ids ++ [Identifier])
  end.

gen_ft(TotalNodes, TotalNodes, Nodes_list, Nodes_list_wc) ->
  Nodes_list_wc;
gen_ft(Iter, TotalNodes, Nodes_list, Nodes_list_wc) ->
  Node_ID = lists:nth(1, lists:nth(Iter, Nodes_list)),
  Node_PID = lists:nth(2, lists:nth(Iter, Nodes_list)),
  Num_entries = round(math:log2(totalSpaces(1, TotalNodes))),

  Ft = pop_ft(1, Node_ID, Iter, Num_entries, TotalNodes, Nodes_list, []),
  gen_ft(Iter + 1, TotalNodes, Nodes_list, Nodes_list_wc ++ [[Node_ID, Node_PID, Ft]]).

pop_ft(NumEntries, Node_ID, Array_ID, NumEntries, TotalNodes, NodesList, Connx) ->
  Next_id = round((Node_ID + math:pow(2, NumEntries - 1))) rem round(math:pow(2, (NumEntries))),
%%  io:format("Curr node is: ~p Next id is: ~p Numentries: ~p ~n",[Node_ID, Next_id, (NumEntries)]),
  Find_Succ = find_succ2(Next_id,  1, NodesList, length(NodesList)+1),
  Connx ++ [Find_Succ];
pop_ft(Iter, Node_ID, Array_ID, NumEntries, TotalNodes, NodesList, Connx) ->

  Next_id = round((Node_ID + math:pow(2, Iter - 1))) rem round(math:pow(2, (NumEntries))),
%%  io:format("Curr node is: ~p Next id is: ~p Numentries: ~p ~n",[Node_ID, Next_id, (NumEntries)]),

  Find_Succ = find_succ2(Next_id,  1, NodesList, length(NodesList)+1),

  pop_ft(Iter + 1, Node_ID, Array_ID, NumEntries, TotalNodes, NodesList, Connx ++ [Find_Succ]).

find_succ(Next_id, ArrayID, NodesList) ->
  Curr_node = lists:nth(ArrayID, NodesList),

  Curr_ID = lists:nth(1, Curr_node),

  io:format("FS :: Curr node is: ~p Next id is: ~p ~n",[Curr_ID, Next_id]),
  if
    (Next_id =< Curr_ID) ->
      Curr_node;
    true ->
      if
        ArrayID == length(NodesList) -> lists:nth(1, NodesList);
        true -> find_succ(Next_id, ArrayID + 1, NodesList)
      end
  end.

find_succ2(Next_id, Len, NodesList, Len) ->
  lists:nth(1, NodesList);
find_succ2(Next_id, ArrayID, NodesList, Len) ->
  Curr_node = lists:nth(ArrayID, NodesList),
  Curr_ID = lists:nth(1, Curr_node),
%%  io:format("FS :: Curr_ID: ~p Next_ID: ~p ~n",[Curr_ID, Next_id]),
  if
    Curr_ID < Next_id -> find_succ2(Next_id, ArrayID+1, NodesList, Len);
    true -> Curr_node
  end.







