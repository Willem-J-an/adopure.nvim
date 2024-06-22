local M = {}

---@param pull_request PullRequest
local function confirm_open_in_diffview(pull_request)
    vim.ui.input({ prompt = "Open in diffview? <CR> / <ESC>" }, function(input)
        if not input then
            return
        end
        local remote_target_name = "origin/" .. vim.split(pull_request.targetRefName, "refs/heads/")[2]
        vim.cmd(":DiffviewOpen " .. remote_target_name)
    end)
end

local function buffer_marker_autocmd(state)
    local augroup = vim.api.nvim_create_augroup("ado.nvim", { clear = true })
    vim.api.nvim_create_autocmd({ "BufEnter" }, {
        group = augroup,
        callback = function()
            if state.pull_request_threads then
                require("ado.marker").create_buffer_extmarks(state.pull_request_threads)
            end
        end,
    })
end

---@param state AdoState
function M.activate_pull_request_context(state)
    require("ado.marker").create_buffer_extmarks(state.pull_request_threads)
    require("ado.git").confirm_checkout_and_open(state.active_pull_request, function()
        confirm_open_in_diffview(state.active_pull_request)
    end)
    buffer_marker_autocmd(state)
end
return M
