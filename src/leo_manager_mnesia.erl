%%======================================================================
%%
%% Leo Manager
%%
%% Copyright (c) 2012 Rakuten, Inc.
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%
%% ---------------------------------------------------------------------
%% Leo Manager - Mnesia.
%% @doc
%% @end
%%======================================================================
-module(leo_manager_mnesia).

-author('Yosuke Hara').

-include("leo_manager.hrl").
-include_lib("leo_commons/include/leo_commons.hrl").
-include_lib("leo_logger/include/leo_logger.hrl").
-include_lib("leo_redundant_manager/include/leo_redundant_manager.hrl").
-include_lib("stdlib/include/qlc.hrl").

%% API
-export([create_storage_nodes/2,
         create_gateway_nodes/2,
         create_system_config/2,
         create_rebalance_info/2,
         create_credentials/2,
         create_buckets/2,
         create_histories/2,

         get_storage_nodes_all/0,
         get_storage_node_by_name/1,
         get_storage_nodes_by_status/1,
         get_gateway_nodes_all/0,
         get_gateway_node_by_name/1,
         get_system_config/0,
         get_rebalance_info_all/0,
         get_rebalance_info_by_node/1,
         get_credentials_all/0,
         get_credential_by_access_key/1,
         get_buckets_all/0,
         get_bucket_by_access_key/1,
         get_bucket_by_name/1,
         get_histories_all/0,

         update_storage_node_status/1,
         update_storage_node_status/2,
         update_gateway_node/1,
         update_system_config/1,
         update_rebalance_info/1,
         update_credential/1,
         update_bucket/1,
         insert_history/1,

         delete_storage_node/1,
         delete_credential_by_access_key/1,
         delete_bucket_by_name/1
         %% delete_history/1
        ]).


%%-----------------------------------------------------------------------
%% Create Table
%%-----------------------------------------------------------------------
%% @doc Create a table of storage-nodes
%%
-spec(create_storage_nodes(atom(), list()) ->
             ok).
create_storage_nodes(Mode, Nodes) ->
    mnesia:create_table(
      storage_nodes,
      [{Mode, Nodes},
       {type, set},
       {record_name, node_state},
       {attributes, record_info(fields, node_state)},
       {user_properties,
        [{node,          {varchar,  undefined},  false, primary,   undefined, undefined, atom     },
         {state,         {varchar,  undefined},  false, undefined, undefined, undefined, atom     },
         {ring_hash_new, {varchar,  undefined},  false, undefined, undefined, undefined, undefined},
         {ring_hash_old, {varchar,  undefined},  false, undefined, undefined, undefined, undefined},
         {when_is,       {integer,  undefined},  false, undefined, undefined, undefined, integer  },
         {error,         {integer,  undefined},  false, undefined, undefined, undefined, integer  }
        ]}
      ]).


%% @doc Create a table of gateway-nodes
%%
-spec(create_gateway_nodes(atom(), list()) ->
             ok).
create_gateway_nodes(Mode, Nodes) ->
    mnesia:create_table(
      gateway_nodes,
      [{Mode, Nodes},
       {type, set},
       {record_name, node_state},
       {attributes, record_info(fields, node_state)},
       {user_properties,
        [{node,          {varchar,  undefined},  false, primary,   undefined, undefined, atom     },
         {state,         {varchar,  undefined},  false, undefined, undefined, undefined, atom     },
         {ring_hash_new, {varchar,  undefined},  false, undefined, undefined, undefined, undefined},
         {ring_hash_old, {varchar,  undefined},  false, undefined, undefined, undefined, undefined},
         {when_is,       {integer,  undefined},  false, undefined, undefined, undefined, integer  },
         {error,         {integer,  undefined},  false, undefined, undefined, undefined, integer  }
        ]}
      ]).


%% @doc Create a table of system-configutation
%%
-spec(create_system_config(atom(), list()) ->
             ok).
create_system_config(Mode, Nodes) ->
    mnesia:create_table(
      system_conf,
      [{Mode, Nodes},
       {type, set},
       {record_name, system_conf},
       {attributes, record_info(fields, system_conf)},
       {user_properties,
        [{version,          {integer,   undefined},  false, primary,   undefined, identity,  integer},
         {n,                {integer,   undefined},  false, undefined, undefined, undefined, integer},
         {r,                {integer,   undefined},  false, undefined, undefined, undefined, integer},
         {w,                {integer,   undefined},  false, undefined, undefined, undefined, integer},
         {d,                {integer,   undefined},  false, undefined, undefined, undefined, integer},
         {bit_of_ring,      {integer,   undefined},  false, undefined, undefined, undefined, integer}
        ]}
      ]).


%% @doc Create a table of rebalance-info
%%
-spec(create_rebalance_info(atom(), list()) ->
             ok).
create_rebalance_info(Mode, Nodes) ->
    mnesia:create_table(
      rebalance_info,
      [{Mode, Nodes},
       {type, set},
       {record_name, rebalance_info},
       {attributes, record_info(fields, rebalance_info)},
       {user_properties,
        [{vnode_id,         {integer,   undefined},  false, primary,   undefined, identity,  integer},
         {node,             {varchar,   undefined},  false, undefined, undefined, undefined, atom   },
         {total_of_objects, {integer,   undefined},  false, undefined, undefined, undefined, integer},
         {num_of_remains,   {integer,   undefined},  false, undifined, undefined, undefined, integer},
         {when_is,          {integer,   undefined},  false, undifined, undefined, undefined, integer}
        ]}
      ]).

%% @doc Create a table of credential
%%
-spec(create_credentials(atom(), list()) ->
             ok).
create_credentials(Mode, Nodes) ->
    mnesia:create_table(
      credentials,
      [{Mode, Nodes},
       {type, set},
       {record_name, credential},
       {attributes, record_info(fields, credential)},
       {user_properties,
        [{access_key_id,    {varchar,   undefined},  false, primary,   undefined, identity,  string },
         {secret_access_key,{varchar,   undefined},  false, undefined, undefined, undefined, string },
         {created,          {integer,   undefined},  false, undifined, undefined, undefined, integer}
        ]}
      ]).


create_buckets(Mode, Nodes) ->
    mnesia:create_table(
      buckets,
      [{Mode, Nodes},
       {type, set},
       {record_name, bucket},
       {attributes, record_info(fields, bucket)},
       {user_properties,
        [{name,             {varchar,   undefined},  false, primary,   undefined, identity,  string },
         {access_key_id,    {varchar,   undefined},  false, undefined, undefined, undefined, string },
         {created,          {integer,   undefined},  false, undifined, undefined, undefined, integer}
        ]}
      ]).


create_histories(Mode, Nodes) ->
    mnesia:create_table(
      histories,
      [{Mode, Nodes},
       {type, set},
       {record_name, history},
       {attributes, record_info(fields, history)},
       {user_properties,
        [{id,               {integer,   undefined},  false, primary,   undefined, undefined, integer},
         {command,          {varchar,   undefined},  false, undefined, undefined, identity,  string },
         {created,          {integer,   undefined},  false, undifined, undefined, undefined, integer}
        ]}
      ]).

%%-----------------------------------------------------------------------
%% GET
%%-----------------------------------------------------------------------
%% @doc Retrieve all storage nodes
%%
-spec(get_storage_nodes_all() ->
             {ok, list()} | not_found | {error, any()}).
get_storage_nodes_all() ->
    F = fun() ->
                Q1 = qlc:q([X || X <- mnesia:table(storage_nodes)]),
                Q2 = qlc:sort(Q1, [{order, ascending}]),
                qlc:e(Q2)
        end,
    Ret = mnesia:transaction(F),
    case Ret of
        {error, Cause} ->
            {error, Cause};
        {atomic, []} ->
            not_found;
        {atomic, ServerNode} ->
            {ok, ServerNode}
    end.


%% @doc Retrieve a storage node by node-name
%%
-spec(get_storage_node_by_name(atom()) ->
             {ok, list()} | not_found | {error, any()}).
get_storage_node_by_name(Node) ->
    F = fun() ->
                Q1 = qlc:q([X || X <- mnesia:table(storage_nodes),
                                 X#node_state.node =:= Node]),
                Q2 = qlc:sort(Q1, [{order, ascending}]),
                qlc:e(Q2)
        end,
    leo_mnesia_utils:read(F).


%% @doc Retrieve storage nodes by status
%%
-spec(get_storage_nodes_by_status(atom()) ->
             {ok, list()} | not_found | {error, any()}).
get_storage_nodes_by_status(Status) ->
    F = fun() ->
                Q1 = qlc:q([X || X <- mnesia:table(storage_nodes),
                                 X#node_state.state =:= Status]),
                Q2 = qlc:sort(Q1, [{order, ascending}]),
                qlc:e(Q2)
        end,
    leo_mnesia_utils:read(F).


%% @doc Retrieve all gateway nodes
%%
-spec(get_gateway_nodes_all() ->
             {ok, list()} | not_found | {error, any()}).
get_gateway_nodes_all() ->
    F = fun() ->
                Q1 = qlc:q([X || X <- mnesia:table(gateway_nodes)]),
                Q2 = qlc:sort(Q1, [{order, ascending}]),
                qlc:e(Q2)
        end,

    Ret = mnesia:transaction(F),
    case Ret of
        {error, Cause} ->
            {error, Cause};
        {atomic, []} ->
            not_found;
        {atomic, Records} ->
            {ok, Records}
    end.


%% @doc Retrieve gateway node info by node-name
%%
-spec(get_gateway_node_by_name(atom()) ->
             {ok, list()} | not_found | {error, any()}).
get_gateway_node_by_name(Node) ->
    F = fun() ->
                Q1 = qlc:q([X || X <- mnesia:table(gateway_nodes),
                                 X#node_state.node =:= Node]),
                Q2 = qlc:sort(Q1, [{order, ascending}]),
                qlc:e(Q2)
        end,
    leo_mnesia_utils:read(F).


%% @doc Retrieve system configuration
%%
-spec(get_system_config() ->
             {ok, #system_conf{}} | not_found | {error, any()}).
get_system_config() ->
    F = fun() ->
                Q1 = qlc:q([X || X <- mnesia:table(system_conf)]),
                Q2 = qlc:sort(Q1, [{order, descending}]),
                qlc:e(Q2)
        end,

    Ret = mnesia:transaction(F),
    case Ret of
        {error, Cause} ->
            {error, Cause};
        {atomic, []} ->
            not_found;
        {atomic, [SystemConfig|_T]} ->
            {ok, SystemConfig}
    end.


%% @doc Retrieve rebalance info
%%
-spec(get_rebalance_info_all() ->
             {ok, list()} | not_found | {error, any()}).
get_rebalance_info_all() ->
    F = fun() ->
                Q1 = qlc:q([X || X <- mnesia:table(rebalance_info)]),
                Q2 = qlc:sort(Q1, [{order, ascending}]),
                qlc:e(Q2)
        end,
    leo_mnesia_utils:read(F).


%% @doc Retrieve rebalance info by node
%%
-spec(get_rebalance_info_by_node(atom()) ->
             {ok, list()} | not_found | {error, any()}).
get_rebalance_info_by_node(Node) ->
    F = fun() ->
                Q1 = qlc:q([X || X <- mnesia:table(rebalance_info),
                                 X#rebalance_info.node =:= Node]),
                Q2 = qlc:sort(Q1, [{order, ascending}]),
                qlc:e(Q2)
        end,
    leo_mnesia_utils:read(F).


%% @doc Retrieve credentials
%%
-spec(get_credentials_all() ->
             {ok, list()} | not_found | {error, any()}).
get_credentials_all() ->
    F = fun() ->
                Q1 = qlc:q([X || X <- mnesia:table(credentials)]),
                Q2 = qlc:sort(Q1, [{order, ascending}]),
                qlc:e(Q2)
        end,

    Ret = mnesia:transaction(F),
    case Ret of
        {error, Why} ->
            {error, Why};
        {atomic, []} ->
            not_found;
        {atomic, Records} ->
            {ok, Records}
    end.


%% @doc Retrieve credential by access-key
%%
-spec(get_credential_by_access_key(string()) ->
             {ok, list()} | not_found | {error, any()}).
get_credential_by_access_key(AccessKey) ->
    F = fun() ->
                Q1 = qlc:q([X || X <- mnesia:table(credentials),
                                 X#credential.access_key_id =:= AccessKey]),
                Q2 = qlc:sort(Q1, [{order, ascending}]),
                qlc:e(Q2)
        end,
    leo_mnesia_utils:read(F).


%% @doc Retrieve all buckets
%%
-spec(get_buckets_all() ->
             {ok, list()} | not_found | {error, any()}).
get_buckets_all() ->
    F = fun() ->
                Q1 = qlc:q([X || X <- mnesia:table(buckets)]),
                Q2 = qlc:sort(Q1, [{order, ascending}]),
                qlc:e(Q2)
        end,

    Ret = mnesia:transaction(F),
    case Ret of
        {error, Why} ->
            {error, Why};
        {atomic, []} ->
            not_found;
        {atomic, Records} ->
            {ok, Records}
    end.


%% @doc Retrieve all buckets
%%
-spec(get_bucket_by_access_key(string()) ->
             {ok, list()} | not_found | {error, any()}).
get_bucket_by_access_key(AccessKey) ->
    F = fun() ->
                Q1 = qlc:q([X || X <- mnesia:table(buckets),
                                 X#bucket.access_key_id =:= AccessKey]),
                Q2 = qlc:sort(Q1, [{order, ascending}]),
                qlc:e(Q2)
        end,
    leo_mnesia_utils:read(F).


%% @doc Retrieve all buckets
%%
-spec(get_bucket_by_name(string()) ->
             {ok, list()} | not_found | {error, any()}).
get_bucket_by_name(BucketName) ->
    F = fun() ->
                Q1 = qlc:q([X || X <- mnesia:table(buckets),
                                 X#bucket.name =:= BucketName]),
                Q2 = qlc:sort(Q1, [{order, ascending}]),
                qlc:e(Q2)
        end,
    leo_mnesia_utils:read(F).


%% @doc get all histories
%%
-spec(get_histories_all() ->
             {ok, list()} | not_found | {error, any()}).
get_histories_all() ->
    F = fun() ->
                Q1 = qlc:q([X || X <- mnesia:table(histories)]),
                Q2 = qlc:sort(Q1, [{order, ascending}]),
                qlc:e(Q2)
        end,

    Ret = mnesia:transaction(F),
    case Ret of
        {error, Why} ->
            {error, Why};
        {atomic, []} ->
            not_found;
        {atomic, Records} ->
            {ok, Records}
    end.


%%-----------------------------------------------------------------------
%% UPDATE
%%-----------------------------------------------------------------------
%% @doc Modify storage-node status
%%
-spec(update_storage_node_status(#node_state{}) ->
             ok | {error, any()}).
update_storage_node_status(NodeState) ->
    update_storage_node_status(update_state, NodeState).

-spec(update_storage_node_status(update | update_state | keep_state | update_chksum | increment_error | init_error, atom()) ->
             ok | {error, any()}).
update_storage_node_status(update, NodeState) ->
    F = fun()-> mnesia:write(storage_nodes, NodeState, write) end,
    leo_mnesia_utils:write(F);

update_storage_node_status(update_state, NodeState) ->
    #node_state{node = Node, state = State} = NodeState,
    case get_storage_node_by_name(Node) of
        {ok, [Cur|_]} ->
            update_storage_node_status(
              update, Cur#node_state{state   = State,
                                     when_is = leo_utils:now()});
        _ ->
            ok
    end;
update_storage_node_status(keep_state, NodeState) ->
    #node_state{node  = Node} = NodeState,
    case get_storage_node_by_name(Node) of
        {ok, [Cur|_]} ->
            update_storage_node_status(
              update, Cur#node_state{when_is = leo_utils:now()});
        _ ->
            ok
    end;

update_storage_node_status(update_chksum, NodeState) ->
    #node_state{node  = Node,
                ring_hash_new = RingHash0,
                ring_hash_old = RingHash1} = NodeState,

    case get_storage_node_by_name(Node) of
        {ok, [Cur|_]} ->
            update_storage_node_status(
              update, Cur#node_state{ring_hash_new = RingHash0,
                                     ring_hash_old = RingHash1,
                                     when_is       = leo_utils:now()});
        _ ->
            ok
    end;

update_storage_node_status(increment_error, NodeState) ->
    #node_state{node = Node} = NodeState,
    case get_storage_node_by_name(Node) of
        {ok, [Cur|_]} ->
            update_storage_node_status(
              update, Cur#node_state{error   = Cur#node_state.error + 1,
                                     when_is = leo_utils:now()});
        _ ->
            ok
    end;

update_storage_node_status(init_error, NodeState) ->
    #node_state{node = Node} = NodeState,
    case get_storage_node_by_name(Node) of
        {ok, [Cur|_]} ->
            update_storage_node_status(
              update, Cur#node_state{error   = 0,
                                     when_is = leo_utils:now()});
        _ ->
            ok
    end;
update_storage_node_status(_, _) ->
    {error, badarg}.


%% @doc Modify gateway-node status
%%
-spec(update_gateway_node(#node_state{}) ->
             ok | {error, any()}).
update_gateway_node(NodeState) ->
    F = fun() -> mnesia:write(gateway_nodes, NodeState, write) end,
    leo_mnesia_utils:write(F).


%% @doc Modify system-configuration
%%
-spec(update_system_config(#system_conf{}) ->
             ok | {error, any()}).
update_system_config(SystemConfig) ->
    F = fun()-> mnesia:write(system_conf, SystemConfig, write) end,
    leo_mnesia_utils:write(F).


%% @doc Modify rebalance-info
%%
-spec(update_rebalance_info(#rebalance_info{}) ->
             ok | {error, any()}).
update_rebalance_info(RebalanceInfo) ->
    F = fun()-> mnesia:write(rebalance_info, RebalanceInfo, write) end,
    leo_mnesia_utils:write(F).


%% @doc Modify credential-info
%%
-spec(update_credential(#credential{}) ->
             ok | {error, any()}).
update_credential(Credential) ->
    F = fun()-> mnesia:write(credentials, Credential, write) end,
    leo_mnesia_utils:write(F).


%% @doc Modify bucket-info
%%
-spec(update_bucket(#bucket{}) ->
             ok | {error, any()}).
update_bucket(Bucket) ->
    F = fun()-> mnesia:write(buckets, Bucket, write) end,
    leo_mnesia_utils:write(F).


%% @doc Modify bucket-info
%%
-spec(insert_history(binary()) ->
             ok | {error, any()}).
insert_history(Command) ->
    [NewCommand|_] = string:tokens(binary_to_list(Command), "\r\n"),
    Id = case get_histories_all() of
             {ok, List} -> length(List) + 1;
             not_found  -> 1;
             {_, Cause} -> {error, Cause}
         end,

    case Id of
        {error, Reason} ->
            {error, Reason};
        _ ->
            F = fun() -> mnesia:write(histories, #history{id = Id,
                                                          command = NewCommand,
                                                          created = leo_utils:now()}, write) end,
            leo_mnesia_utils:write(F)
    end.


%%-----------------------------------------------------------------------
%% DELETE
%%-----------------------------------------------------------------------
%% @doc Remove storage-node by name
-spec(delete_storage_node(atom()) ->
             ok | {error, any()}).
delete_storage_node(Node) ->
    F = fun() ->
                mnesia:delete_object(storage_nodes, Node, write)
        end,
    leo_mnesia_utils:delete(F).


%% @doc  Remove credential-info by access-key-id
-spec(delete_credential_by_access_key(string()) ->
             ok | not_found | {error, any()}).
delete_credential_by_access_key(AccessKey) ->
    case get_credential_by_access_key(AccessKey) of
        {ok, [Credential|_]} ->
            F = fun() ->
                        mnesia:delete_object(credentials, Credential, write)
                end,
            leo_mnesia_utils:delete(F);
        Error ->
            Error
    end.


%% @doc Remove bucket-info by bucket's name
-spec(delete_bucket_by_name(string()) ->
             ok | not_found | {error, any()}).
delete_bucket_by_name(Name) ->
    case get_bucket_by_name(Name) of
        {ok, [Bucket|_]} ->
            F = fun() ->
                        mnesia:delete_object(buckets, Bucket, write)
                end,
            leo_mnesia_utils:delete(F);
        Error ->
            Error
    end.

