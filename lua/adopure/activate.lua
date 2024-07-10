local M = {}

---@param pull_request adopure.PullRequest
local function confirm_open_in_diffview(pull_request)
    vim.ui.input({ prompt = "Open in diffview? <CR> / <ESC>" }, function(input)
        if not input then
            return
        end
        local merge_base = require("adopure.git").get_merge_base(pull_request)
        vim.cmd(":DiffviewOpen " .. merge_base)
    end)
end

local function buffer_marker_autocmd(state)
    local augroup = vim.api.nvim_create_augroup("adopure.nvim", { clear = true })
    vim.api.nvim_create_autocmd({ "BufEnter" }, {
        group = augroup,
        callback = function()
            if state.pull_request_threads then
                require("adopure.marker").create_buffer_extmarks(state.pull_request_threads)
            end
        end,
    })
end

---@param state adopure.AdoState
function M.activate_pull_request_context(state)
    require("adopure.marker").create_buffer_extmarks(state.pull_request_threads)
    require("adopure.git").confirm_checkout_and_open(state.active_pull_request, function()
        confirm_open_in_diffview(state.active_pull_request)
    end)
    buffer_marker_autocmd(state)
end
return M
