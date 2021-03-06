%%====================================================================
%%
%% Leo FS Manager
%%
%% Copyright (c) 2012
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
%% -------------------------------------------------------------------
%% LeoFS Manager - Constant/Macro/Record
%%
%% -------------------------------------------------------------------
-author('yosuke hara').
-vsn('0.9.1').
-include_lib("eunit/include/eunit.hrl").

%% constants.
-define(SHUTDOWN_WAITING_TIME, 2000).
-define(MAX_RESTART,              5).
-define(MAX_TIME,                60).

-ifdef(TEST).
-define(DEF_TIMEOUT,           1000).
-define(DEF_MONITOR_INTERVAL,  5000).
-else.
-define(DEF_TIMEOUT,           3000).
-define(DEF_MONITOR_INTERVAL, 20000).
-endif.

-define(LONG_OP_TIMEOUT,           600000).

-define(SYSTEM_CONF_FILE,  "conf/leofs.conf").

%% command-related.
-define(COMMAND_ERROR,        "Command Error").
-define(OK,                   "OK\r\n").
-define(ERROR,                "ERROR\r\n").
-define(CRLF,                 "\r\n").
-define(STORED,               "STORED\r\n").
-define(NOT_STORED,           "NOT_STORED\r\n").
-define(DELETED,              "DELETED\r\n").
-define(NOT_FOUND,            "NOT FOUND\r\n").
-define(SERVER_ERROR,         "SERVER_ERROR").

-define(HELP,                 "help\r\n").
-define(QUIT,                 "quit\r\n").
-define(BYE,                  "BYE\r\n").
-define(COMMAND_DELIMITER,    " \r\n").
-define(VERSION,              "version").
-define(STATUS,               "status").
-define(ATTACH_SERVER,        "attach").
-define(DETACH_SERVER,        "detach").
-define(SUSPEND,              "suspend").
-define(RESUME,               "resume").
-define(START,                "start").
-define(REBALANCE,            "rebalance").
-define(COMPACT,              "compact").
-define(GEN_S3_KEY,           "gen-s3-key").
-define(STORAGE_STATS,        "du").
-define(WHEREIS,              "whereis").
-define(HISTORY,              "history").
-define(PURGE,                "purge").


%% membership.
-define(DEF_NUM_OF_ERROR_COUNT, 3).

%% error.
-define(ERROR_COULD_NOT_CONNECT,        "could not connect").
-define(ERROR_FAILED_COMPACTION,        "failed compaction").
-define(ERROR_FAILED_GET_STORAGE_STATS, "failed to get storage stats").


%% records.
%%
-record(rebalance_info, {
          vnode_id         = -1  :: integer(),
          node                   :: atom(),
          total_of_objects = 0   :: integer(),
          num_of_remains   = 0   :: integer(),
          when_is          = 0   :: integer() %% Posted at
         }).

-record(credential, {
          access_key_id = []     :: string(), %% Access Key ID
          secret_access_key = [] :: string(), %% SHA-1(Secret Access Key)
          created = -1           :: integer() %% Created at
         }).

-record(bucket, {
          name = []              :: string(), %% Bucket name
          access_key_id = []     :: string(), %% Access Key ID
          permission = []        :: string(), %% Permission
          created = -1           :: integer() %% Created
         }).

-record(history, {
          id                     :: integer(),
          command = []           :: string(), %% Command
          created = -1           :: integer() %% Created
         }).


%% macros.
%%
-define(env_mode_of_manager(),
        case application:get_env(leo_manager, manager_mode) of
            {ok, EnvModeOfManager} -> EnvModeOfManager;
            _ -> 'master'
        end).

-define(env_partner_of_manager_node(),
        case application:get_env(leo_manager, manager_partners) of
            {ok, EnvPartnerOfManagerNode} -> EnvPartnerOfManagerNode;
            _ -> []
        end).

