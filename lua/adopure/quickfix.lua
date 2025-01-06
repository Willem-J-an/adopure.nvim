local Path = require("plenary.path")
---@mod adopure.quickfix
local M = {}

---Render pull request threads in quickfix panel.
---This allows for a workflow of quickly jumping to various comment threads in the code.
---@param state adopure.AdoState
---@param _ table
function M.render_quickfix(state, _)
    local entries = vim.iter(state.pull_request_threads)
        :filter(function(thread) ---@param thread adopure.AdoThread
            return thread:is_active_thread()
        end)
        :map(function(thread) ---@param thread adopure.AdoThread
            local context = thread:thread_context()
            assert(context, "Context not nil for active thread;")
            return {
                filename = Path:new(state.root_path, thread:targeted_file_path().filename):make_relative(),
                lnum = vim.F.if_nil(context.rightFileStart.line, 1),
                col = vim.F.if_nil(context.rightFileStart.offset, 1),
                text = thread:format_item(),
            }
        end)
        :totable()
    vim.cmd("copen")
    vim.fn.setqflist({}, " ", { nr = "$", items = entries })
end
return M
