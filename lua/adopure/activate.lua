local Path = require("plenary.path")
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
        callback = function(args)
            if state.pull_request_threads and args.file ~= "" then
                require("adopure.marker").create_buffer_extmarks(state.pull_request_threads, args.buf, args.file)
            end
        end,
    })
end

function M.disabled_buffer_marker_autocmd()
    local augroup = vim.api.nvim_create_augroup("adopure.nvim", { clear = true })
    local namespace = vim.api.nvim_create_namespace("adopure-marker")
    vim.api.nvim_buf_clear_namespace(0, namespace, 0, -1)
    vim.api.nvim_create_autocmd({ "BufEnter" }, {
        group = augroup,
        callback = function(args)
            vim.api.nvim_buf_clear_namespace(args.buf, namespace, 0, -1)
        end,
    })
end

---@param state adopure.AdoState
function M.activate_pull_request_context(state)
    local focused_file_path = Path:new(vim.fn.expand("%:.")).filename
    require("adopure.marker").create_buffer_extmarks(state.pull_request_threads, 0, focused_file_path)
    require("adopure.git").confirm_checkout_and_open(state.active_pull_request, function()
        confirm_open_in_diffview(state.active_pull_request)
    end)
    buffer_marker_autocmd(state)
end
return M
