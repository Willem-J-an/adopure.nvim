
---@toc adopure.contents

---@mod adopure

---@tag adopure.cli
---@brief [[
---The plugin provides an opinionated workflow to interact with Azure DevOps Pull Requests.
---
---adopure.lua contains the main nvim command line entry point of the plugin.
---The entry-point is called using the command: AdoPure.
---The command is auto-completing when used in neovim command line. Valid options include:
---
--->vim
--- :AdoPure [ load ] [ context | threads ] [ opts ]
---<
---Loads specified argument into state.
---
---     *context*: load open pull requests; prompt user to pick one.
---     Note: Subsequent commands will operate on the chosen PR.
---
---     *threads*: Fetch comment threads from Azure DevOps.
---
--->vim
--- :AdoPure [ open ] [ quickfix | thread_picker | new_thread | existing_thread ] [ opts ]
---<
---Opens specified argument in the editor.
---
---     *quickfix*: Open comment threads in quickfix window.
---
---     *thread_picker*: Open a picker with all comment threads.
---     Supports filtering like so:
--->vim
---     :AdoPure open thread_picker {thread_filters={'hide_system', 'hide_closed'}}
---<
---     *new_thread*: Opens a window to write a comment on code selection.
---
---     *existing_thread*: Opens a window with an existing comment thread.
---
--->vim
--- :AdoPure [ submit ] [ comment | vote | thread_status ] [ opts ]
---<
---Submits specified argument to Azure DevOps.
---
---     *comment*: Submit new comment or reply; must be in new_thread or existing_thread window.
---
---     *vote*: Submit a new vote on the pull request.
---
---     *thread_status*: Submit a thread_status change; must be in existing_thread window.
---
--->vim
--- :AdoPure [ unload ]
---<
---Unloads plugin state and remove plugin marks.
---
---Note: If no arguments args provided, the user will be prompted.
---@brief ]]

local adopure = {}

---@type adopure.StateManager|nil
local state_manager

local function completer(load_args, arg_lead)
    return vim.iter(load_args)
        :filter(function(load_arg)
            return load_arg:find(arg_lead) ~= nil
        end)
        :totable()
end

---@param sub_impl string[]
---@param subcommand_args string[]
---@param subcommand string
local function execute_or_prompt(sub_impl, subcommand_args, subcommand)
    if #subcommand_args == 0 then
        vim.ui.select(vim.tbl_keys(sub_impl), { "Choose target" }, function(choice)
            if not choice then
                vim.notify("AdoPure: Unknown " .. subcommand .. " target", vim.log.levels.ERROR)
                return
            end
            sub_impl[choice](subcommand_args[2] or {})
        end)
        return
    end
    local load_opts = function()
        return load("return " .. (subcommand_args[2] or ""), "t")()
    end
    local ok, opts = pcall(load_opts)
    sub_impl[subcommand_args[1]](ok and opts or {})
end

---@private
---@class adopure.SubCommand
---@field impl fun(args:string[])
---@field complete_args? string[]

---@type table<string, adopure.SubCommand>
local subcommand_tbl = {
    unload = {
        complete_args = {},
        impl = function(_)
            state_manager = nil
            require("adopure.activate").disabled_buffer_marker_autocmd()
        end,
    },
    load = {
        complete_args = { "context", "threads" },
        impl = function(args)
            local sub_impl = {
                context = function(opts)
                    local manager = adopure.load_state_manager()
                    manager:choose_and_activate(opts)
                end,
                threads = function(opts)
                    adopure.get_loaded_state():load_pull_request_threads(opts)
                end,
            }
            execute_or_prompt(sub_impl, args, "load")
        end,
    },
    submit = {
        complete_args = { "comment", "vote", "thread_status" },
        impl = function(args)
            local sub_impl = {
                comment = function(opts)
                    require("adopure.thread").submit_comment(adopure.get_loaded_state(), opts)
                end,
                vote = function(opts)
                    require("adopure.review").submit_vote(adopure.get_loaded_state(), opts)
                end,
                thread_status = function(opts)
                    require("adopure.thread").update_thread_status(adopure.get_loaded_state(), opts)
                end,
            }
            execute_or_prompt(sub_impl, args, "submit")
        end,
    },
    open = {
        complete_args = { "quickfix", "thread_picker", "new_thread", "existing_thread" },
        impl = function(args)
            local sub_impl = {
                quickfix = function(opts)
                    require("adopure.quickfix").render_quickfix(adopure.get_loaded_state().pull_request_threads, opts)
                end,
                thread_picker = function(opts)
                    require("adopure.pickers.thread").choose_thread(adopure.get_loaded_state(), opts)
                end,
                new_thread = function(opts)
                    require("adopure.thread").new_thread_window(adopure.get_loaded_state(), opts)
                end,
                existing_thread = function(opts)
                    require("adopure.thread").open_thread_window(adopure.get_loaded_state(), opts)
                end,
            }
            execute_or_prompt(sub_impl, args, "open")
        end,
    },
}

---Main command line entry point for the module.
---@param opts table provided by neovim user command context.
---@usage lua [[
---vim.cmd(':AdoPure load context {}')
---@usage ]]
function adopure.ado_pure(opts)
    local fargs = opts.fargs
    local subcommand_key = fargs[1]

    local args = #fargs > 1 and vim.list_slice(fargs, 2, #fargs) or {}
    local subcommand = subcommand_tbl[subcommand_key]
    if not subcommand then
        vim.ui.select(vim.tbl_keys(subcommand_tbl), {
            prompt = "Select subcommand...",
        }, function(choice)
            if not choice then
                vim.notify("AdoPure: Unknown command: " .. subcommand_key, vim.log.levels.ERROR)
                return
            end
            adopure.ado_pure({ fargs = { choice } })
        end)
        return
    end
    subcommand.impl(args)
end

---Initialize state_manager, contains repository and all open pull requests.
---If not using the vim command line interface, call this first.
---After getting a state_manager, load a PR into context with the choose_and_activate method.
---@return adopure.StateManager
---@usage lua [[
---M.load_state_manager():choose_and_activate()
---@usage ]]
function adopure.load_state_manager()
    if not state_manager then
        local context = require("adopure.state").AdoContext:new()
        state_manager = require("adopure.state").StateManager:new(context)
    end
    assert(state_manager, "StateManager should not be nil after loading;")
    return state_manager
end

---Return state of the plugin; raises if no pull request has been loaded into context.
---If not using the vim command line interface, use adopure.load_state_manager.
---Then call this to get state required for the other commands.
---@return adopure.AdoState
function adopure.get_loaded_state()
    assert(state_manager and state_manager.state, "Choose and activate a pull request first;")
    return state_manager.state
end

---@private
function adopure.auto_completer(arg_lead, cmdline, _)
    local subcmd_key, subcmd_arg_lead = cmdline:match("^'?<?,?'?>?AdoPure*%s(%S+)%s(.*)$")
    if subcmd_key and subcmd_arg_lead and subcommand_tbl[subcmd_key] and subcommand_tbl[subcmd_key].complete_args then
        return completer(subcommand_tbl[subcmd_key].complete_args, subcmd_arg_lead)
    end

    if cmdline:match("^'?<?,?'?>?AdoPure*%s+%w*$") then
        local subcommand_keys = vim.tbl_keys(subcommand_tbl)
        return completer(subcommand_keys, arg_lead)
    end
end

return adopure
