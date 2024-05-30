---@type StateManager|nil
local state_manager
---@return AdoState
local function get_loaded_state()
    assert(state_manager and state_manager.state, "Choose and activate a pull request first;")
    return state_manager.state
end
local M = {}

function M.load_pull_request_context()
    local context = require("ado.state").AdoContext:new()
    state_manager = require("ado.state").StateManager:new(context)
    state_manager:choose_and_activate()
end

function M.load_pull_request_threads()
    get_loaded_state():load_pull_request_threads()
end

function M.submit_comment()
    require("ado.thread").submit_comment(get_loaded_state())
end

function M.update_thread_status()
    require("ado.thread").update_thread_status(get_loaded_state())
end

function M.new_thread_window()
    require("ado.thread").new_thread_window(get_loaded_state())
end

function M.open_thread_window()
    require("ado.thread").open_thread_window(get_loaded_state(), nil)
end

function M.render_quickfix()
    require("ado.quickfix").render_quickfix(get_loaded_state().pull_request_threads)
end

function M.thread_picker()
    require("ado.pickers.thread").choose_thread(get_loaded_state())
end

return M
