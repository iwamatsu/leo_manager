%%======================================================================
%%
%% Leo Manaegr
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
%% Leo Manager - Supervisor.
%% @doc
%% @end
%%======================================================================
-module(leo_manager_sup).

-author('Yosuke Hara').

-behaviour(supervisor).

-include("leo_manager.hrl").
-include("tcp_server.hrl").
-include_lib("leo_commons/include/leo_commons.hrl").
-include_lib("leo_logger/include/leo_logger.hrl").
-include_lib("eunit/include/eunit.hrl").

%% External API
-export([start_link/0, stop/0]).
-export([create_mnesia_tables/2]).


%% Callbacks
-export([init/1]).

-define(CHECK_INTERVAL, 250).

%%-----------------------------------------------------------------------
%% External API
%%-----------------------------------------------------------------------
%% @spec () -> ok
%% @doc start link...
%% @end
start_link() ->
    ListenPort     = ?env_listening_port(leo_manager),
    NumOfAcceptors = ?env_num_of_acceptors(leo_manager),
    Mode           = ?env_mode_of_manager(),

    [RedundantNodes0|_] = ?env_partner_of_manager_node(),
    RedundantNodes1     = [{Mode, node()},
                           {'partner', case is_atom(RedundantNodes0) of
                                           true  -> RedundantNodes0;
                                           false -> list_to_atom(RedundantNodes0)
                                       end}],

    case supervisor:start_link({local, ?MODULE}, ?MODULE,
                               [#tcp_server_params{port = ListenPort,
                                                   num_of_listeners = NumOfAcceptors}]) of
        {ok, Pid} ->
            %% Launch Logger
            DefLogDir = "./log/",
            LogDir    = case application:get_env(log_appender) of
                            {ok, [{file, Options}|_]} ->
                                proplists:get_value(path, Options,  DefLogDir);
                            _ ->
                                DefLogDir
                        end,
            ok = leo_logger_client_message:new(LogDir, ?env_log_level(leo_manager), log_file_appender()),

            %% Launch Statistics
            ok = leo_statistics_api:start(?MODULE, leo_manager,
                                          [{snmp, [leo_statistics_metrics_vm]},
                                           {stat, [leo_statistics_metrics_vm]}]),

            %% Launch Redundant-manager
            SystemConf = load_system_config(),
            ok = leo_redundant_manager_api:start(Mode, RedundantNodes1, ?env_queue_dir(leo_manager),
                                                 [{n,           SystemConf#system_conf.n},
                                                  {r,           SystemConf#system_conf.r},
                                                  {w,           SystemConf#system_conf.w},
                                                  {d,           SystemConf#system_conf.d},
                                                  {bit_of_ring, SystemConf#system_conf.bit_of_ring}]),

            %% Launch Auth
            ok = leo_s3_auth_api:start(master, []),

            %% Launch Bucket
            ok = leo_s3_bucket_api:start(master, []),

            %% Launch Mnesia and create that tables
            timer:apply_after(?CHECK_INTERVAL, ?MODULE, create_mnesia_tables, [Mode, RedundantNodes1]),
            {ok, Pid};
        Error ->
            Error
    end.


%% @doc Create mnesia tables
%%
-spec(create_mnesia_tables(master | slave, atom()) ->
             ok | {error, any()}).
create_mnesia_tables(_, []) ->
    {error, badarg};
create_mnesia_tables(Mode, RedundantNodes) ->
    case proplists:get_value('partner', RedundantNodes) of
        undefined ->
            create_mnesia_tables1(Mode, RedundantNodes);
        PartnerNode ->
            case net_adm:ping(PartnerNode) of
                pong ->
                    create_mnesia_tables1(Mode, RedundantNodes);
                pang ->
                    timer:apply_after(?CHECK_INTERVAL, ?MODULE, create_mnesia_tables, [Mode, RedundantNodes])
            end
    end.


%% @spec () -> ok |
%%             not_started
%% @doc stop process.
%% @end
stop() ->
    case whereis(?MODULE) of
        Pid when is_pid(Pid) == true ->
            exit(Pid, shutdown),
            ok;
        _ -> not_started
    end.

%% ---------------------------------------------------------------------
%% Callbacks
%% ---------------------------------------------------------------------
%% @spec (Params) -> ok
%% @doc stop process.
%% @end
%% @private
init([TCPServerParams]) ->
    ChildProcs =
        [{leo_manager_controller,
          {leo_manager_controller, start_link, [TCPServerParams]},
          permanent,
          ?SHUTDOWN_WAITING_TIME,
          worker,
          [leo_manager_controller]},

         {leo_manager_cluster_monitor,
          {leo_manager_cluster_monitor, start_link, []},
          permanent,
          ?SHUTDOWN_WAITING_TIME,
          worker,
          [leo_manager_cluster_monitor]}
        ],
    {ok, {_SupFlags = {one_for_one, ?MAX_RESTART, ?MAX_TIME}, ChildProcs}}.


%% ---------------------------------------------------------------------
%% Inner Function(s)
%% ---------------------------------------------------------------------
%% @doc Create mnesia tables
%% @private
-spec(create_mnesia_tables1(master | slave, list()) ->
             ok | {error, any()}).
create_mnesia_tables1(master = Mode, Nodes0) ->
    Nodes1 = lists:map(fun({_, N}) -> N end, Nodes0),

    case mnesia:create_schema(Nodes1) of
        ok ->
            try
                %% create mnesia's schema.
                mnesia:create_schema(Nodes1),
                rpc:multicall(Nodes1, application, stop,  [mnesia]),
                rpc:multicall(Nodes1, application, start, [mnesia]),

                %% create table into the mnesia.
                leo_manager_mnesia:create_system_config(disc_copies, Nodes1),
                leo_manager_mnesia:create_storage_nodes(disc_copies, Nodes1),
                leo_manager_mnesia:create_gateway_nodes(disc_copies, Nodes1),
                leo_manager_mnesia:create_rebalance_info(disc_copies, Nodes1),
                leo_manager_mnesia:create_histories(disc_copies, Nodes1),

                leo_redundant_manager_table_ring:create_ring_current(disc_copies, Nodes1),
                leo_redundant_manager_table_ring:create_ring_prev(disc_copies, Nodes1),
                leo_redundant_manager_table_member:create_members(disc_copies, Nodes1),

                leo_s3_auth_api:create_credential_table(disc_copies, Nodes1),
                leo_s3_bucket_api:create_bucket_table(disc_copies, Nodes1),
                {ok, _} = load_system_config_with_store_data()

            catch _:Reason ->
                    ?error("create_mnesia_tables1/3", "cause:~p", [Reason])
            end,
            ok;
        {error,{_,{already_exists, _}}} ->
            create_mnesia_tables2();
        {_, Cause} ->
            timer:apply_after(?CHECK_INTERVAL, ?MODULE, create_mnesia_tables, [Mode, Nodes0]),
            ?error("create_mnesia_tables1/3", "cause:~p", [Cause]),
            {error, Cause}
    end;
create_mnesia_tables1(slave, _Nodes) ->
    create_mnesia_tables2().


-spec(create_mnesia_tables2() ->
             ok | {error, any()}).
create_mnesia_tables2() ->
    application:start(mnesia),
    timer:sleep(1000),

    case catch mnesia:system_info(tables) of
        Tbls when length(Tbls) > 1 ->
            ok = mnesia:wait_for_tables(Tbls, 30000),
            ok;
        Tbls when length(Tbls) =< 1 ->
            {error, no_exists};
        Error ->
            ?error("create_mnesia_tables2/2", "cause:~p", [Error]),
            Error
    end.


%% @doc Get log-file appender from env
%% @private
-spec(log_file_appender() ->
             list()).
log_file_appender() ->
    case application:get_env(leo_manager, log_appender) of
        undefined   -> log_file_appender([], []);
        {ok, Value} -> log_file_appender(Value, [])
    end.

-spec(log_file_appender(list(), list()) ->
             list()).
log_file_appender([], []) ->
    [{?LOG_ID_FILE_INFO,  ?LOG_APPENDER_FILE},
     {?LOG_ID_FILE_ERROR, ?LOG_APPENDER_FILE}];
log_file_appender([], Acc) ->
    lists:reverse(Acc);
log_file_appender([{Type, _}|T], Acc) when Type == file ->
    log_file_appender(T, [{?LOG_ID_FILE_ERROR, ?LOG_APPENDER_FILE}|[{?LOG_ID_FILE_INFO, ?LOG_APPENDER_FILE}|Acc]]).

%% @TODO
%% log_file_appender([{Type, _}|T], Acc) when Type == zmq ->
%%     log_file_appender(T, [{?LOG_ID_ZMQ, ?LOG_APPENDER_ZMQ}|Acc]).


%% @doc load a system config file
%% @end
%% @private
load_system_config() ->
    {ok, Props} = application:get_env(leo_manager, system),
    SystemConf = #system_conf{n = proplists:get_value(n, Props, 1),
                              w = proplists:get_value(w, Props, 1),
                              r = proplists:get_value(r, Props, 1),
                              d = proplists:get_value(d, Props, 1),
                              bit_of_ring = proplists:get_value(bit_of_ring, Props, 128)},
    SystemConf.

%% @doc load a system config file. a system config file store to mnesia.
%% @end
%% @private
-spec(load_system_config_with_store_data() ->
             {ok, #system_conf{}} | {error, any()}).
load_system_config_with_store_data() ->
    SystemConf = load_system_config(),

    case leo_manager_mnesia:update_system_config(SystemConf) of
        ok ->
            {ok, SystemConf};
        Error ->
            Error
    end.
