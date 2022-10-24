-module(main).
-author("User").
-export([chord_start/2, find_succ/3]).

-define(Mult_factor, 4).
-define(ReplicationFactor, 4).

%%Calculating total empty spaces needed in the ring
totalSpaces(Power, TotalNodes) ->
  if
    Power < TotalNodes -> totalSpaces(Power * 2, TotalNodes);
    true -> Power
  end.

%%STARTING PROTOCOL
chord_start(TotalNodes, NumRequests) ->
  if
    TotalNodes<100 -> io:format("Enter nodes greater or equal to 100 for less collision frequency ~n"), erlang:exit(normal);
    true -> nothing
  end,

%%  starting hop calculator (listens for finishing of queries)
  HopCalc_PID = hopCalculator:startCalc(0,0, NumRequests),
  TotalSpaces = totalSpaces(1, TotalNodes),
  io:format("TotalSpaces in chord ~p ~n ", [TotalSpaces]),

%%  Similar to join function in API
  Nodes_list = add_nodes(TotalNodes, round(TotalSpaces), no_peers, [], [], HopCalc_PID),
  io:format("Stage 1 ~n "),

  %%  Similar to stabilize function in API, genft called periodically at various points in code
  Nodes_list_wc = gen_ft(1, TotalNodes+1, Nodes_list, []),
  io:format("Stage 2 ~n "),


  send_ft(1, Nodes_list_wc, length(Nodes_list_wc)+1, NumRequests, Nodes_list),
  io:format("Stage 3 ~n "),

%%  Instructing all nodes to start transmitting
  send_ft2(1, Nodes_list_wc, length(Nodes_list_wc)+1, NumRequests, Nodes_list),
  io:format("Stage 4 ~n ").

send_ft(Len, _, Len, _, _) ->
  io:format("Done sending ~n");
send_ft(Iter, Nodes_list_wc, Len, NumRequests, Nodes_list) ->
  Curr_node = lists:nth(Iter, Nodes_list_wc),
  Curr_node_pid = lists:nth(2, Curr_node),
  Finger = lists:nth(3, Curr_node),
  Curr_node_pid ! {ok, Finger, Nodes_list, Iter},
  send_ft(Iter+1, Nodes_list_wc, Len, NumRequests, Nodes_list).

send_ft2(Len, _, Len, _, _) ->
  io:format("Done sending ~n");
send_ft2(Iter, Nodes_list_wc, Len, NumRequests, Nodes_list) ->
  Curr_node = lists:nth(Iter, Nodes_list_wc),
  Curr_node_pid = lists:nth(2, Curr_node),
  Curr_node_pid ! {send_requests, NumRequests},
  send_ft2(Iter+1, Nodes_list_wc, Len, NumRequests, Nodes_list).

add_nodes(0, _, _, Nodes_list, _, _) ->
  lists:sort(Nodes_list);
add_nodes(TotalNodes, TotalSpaces, no_peers, Nodes_list, Occupied_Ids, HopCalc_PID) ->
  Random_ID = rand:uniform(1000000000),
  Hashed_data = crypto:hash(sha, <<Random_ID>>),
  <<Hash_to_int:160/integer>> = Hashed_data,
  Identifier = Random_ID rem TotalSpaces,
  NodePID = node:startLink(Identifier, null, null, null, TotalSpaces, null, null, HopCalc_PID),
  add_nodes(TotalNodes - 1, TotalSpaces, {Identifier, self()}, Nodes_list ++ [[Identifier, NodePID]], Occupied_Ids ++ [Identifier], HopCalc_PID);

add_nodes(TotalNodes, TotalSpaces, Peer = {_, _}, Nodes_list, Occupied_Ids, HopCalc_PID) ->
  Random_ID = rand:uniform(1000000000),
  Hashed_data = crypto:hash(sha, <<Random_ID>>),
  <<Hash_to_int:160/integer>> = Hashed_data,
  Identifier = Random_ID rem TotalSpaces,
  Already_occupied_id = lists:member(Identifier, Occupied_Ids),
  if
    Already_occupied_id ->
      add_nodes(TotalNodes, TotalSpaces, Peer, Nodes_list, Occupied_Ids, HopCalc_PID);
    true ->
      NodePID = node:startLink(Identifier, null, {Identifier, self()}, null, TotalSpaces, null, null, HopCalc_PID),

      add_nodes(TotalNodes - 1, TotalSpaces, Peer, Nodes_list ++ [[Identifier, NodePID]], Occupied_Ids ++ [Identifier], HopCalc_PID)
  end.

gen_ft(TotalNodes, TotalNodes, _, Nodes_list_wc) ->
  Nodes_list_wc;
gen_ft(Iter, TotalNodes, Nodes_list, Nodes_list_wc) ->
  Node_ID = lists:nth(1, lists:nth(Iter, Nodes_list)),
  Node_PID = lists:nth(2, lists:nth(Iter, Nodes_list)),
  Num_entries = round(math:log2(totalSpaces(1, TotalNodes))),
  Ft = pop_ft(1, Node_ID, Iter, Num_entries, TotalNodes, Nodes_list, []),
  gen_ft(Iter + 1, TotalNodes, Nodes_list, Nodes_list_wc ++ [[Node_ID, Node_PID, Ft]]).

pop_ft(NumEntries, Node_ID, _, NumEntries, _, NodesList, Connx) ->
  Next_id = round((Node_ID + math:pow(2, NumEntries - 1))) rem round(math:pow(2, (NumEntries))),
  Find_Succ = find_succ2(Next_id,  1, NodesList, length(NodesList)+1),
  Connx ++ [Find_Succ];
pop_ft(Iter, Node_ID, Array_ID, NumEntries, TotalNodes, NodesList, Connx) ->
  Next_id = round((Node_ID + math:pow(2, Iter - 1))) rem round(math:pow(2, (NumEntries))),
  Find_Succ = find_succ2(Next_id,  1, NodesList, length(NodesList)+1),
  pop_ft(Iter + 1, Node_ID, Array_ID, NumEntries, TotalNodes, NodesList, Connx ++ [Find_Succ]).

%% FIND SUCCESSOR FUNCTION
find_succ(Next_id, ArrayID, NodesList) ->
  Curr_node = lists:nth(ArrayID, NodesList),
  Curr_ID = lists:nth(1, Curr_node),
  if
    (Next_id =< Curr_ID) ->
      Curr_node;
    true ->
      if
        ArrayID == length(NodesList) -> lists:nth(1, NodesList);
        true -> find_succ(Next_id, ArrayID + 1, NodesList)
      end
  end.

%% FIND SUCCESSOR ACCOMPANYING FUNCTION

find_succ2(_, Len, NodesList, Len) ->
  lists:nth(1, NodesList);
find_succ2(Next_id, ArrayID, NodesList, Len) ->
  Curr_node = lists:nth(ArrayID, NodesList),
  Curr_ID = lists:nth(1, Curr_node),
  if
    Curr_ID < Next_id -> find_succ2(Next_id, ArrayID+1, NodesList, Len);
    true -> Curr_node
  end.







