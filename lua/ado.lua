local M = {}

---@type StateManager|nil
local state_manager
---@return AdoState
function M.get_loaded_state()
    assert(state_manager and state_manager.state, "Choose and activate a pull request first;")
    return state_manager.state
end

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

---@class SubCommand
---@field impl fun(args:string[])
---@field complete_args? string[]

---Initial load of state_manager with all open PRs;
---@return StateManager
function M.load_state_manager()
    if not state_manager then
        local context = require("ado.state").AdoContext:new()
        state_manager = require("ado.state").StateManager:new(context)
    end
    assert(state_manager, "StateManager should not be nil after loading;")
    return state_manager
end

---@type table<string, SubCommand>
local subcommand_tbl = {
    load = {
        complete_args = { "context", "threads" },
        impl = function(args)
            local sub_impl = {
                context = function(opts)
                    local manager = M.load_state_manager()
                    manager:choose_and_activate(opts)
                end,
                threads = function(opts)
                    M.get_loaded_state():load_pull_request_threads(opts)
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
                    require("ado.thread").submit_comment(M.get_loaded_state(), opts)
                end,
                vote = function(opts)
                    require("ado.review").submit_vote(M.get_loaded_state(), opts)
                end,
                thread_status = function(opts)
                    require("ado.thread").update_thread_status(M.get_loaded_state(), opts)
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
                    require("ado.quickfix").render_quickfix(M.get_loaded_state().pull_request_threads, opts)
                end,
                thread_picker = function(opts)
                    require("ado.pickers.thread").choose_thread(M.get_loaded_state(), opts)
                end,
                new_thread = function(opts)
                    require("ado.thread").new_thread_window(M.get_loaded_state(), opts)
                end,
                existing_thread = function(opts)
                    require("ado.thread").open_thread_window(M.get_loaded_state(), opts)
                end,
            }
            execute_or_prompt(sub_impl, args, "open")
        end,
    },
}

---@param opts table
function M.ado_pure(opts)
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
            M.ado_pure({ fargs = { choice } })
        end)
        return
    end
    subcommand.impl(args)
end

function M.auto_completer(arg_lead, cmdline, _)
    local subcmd_key, subcmd_arg_lead = cmdline:match("^'?<?,?'?>?AdoPure*%s(%S+)%s(.*)$")
    if subcmd_key and subcmd_arg_lead and subcommand_tbl[subcmd_key] and subcommand_tbl[subcmd_key].complete_args then
        return completer(subcommand_tbl[subcmd_key].complete_args, subcmd_arg_lead)
    end

    if cmdline:match("^'?<?,?'?>?AdoPure*%s+%w*$") then
        local subcommand_keys = vim.tbl_keys(subcommand_tbl)
        return completer(subcommand_keys, arg_lead)
    end
end

return M
