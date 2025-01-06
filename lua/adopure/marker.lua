local M = {
    ---@type table<number, adopure.Thread>: <extmark_id, pull_request_thread>
    buffer_extmarks = {},
    ---@type table<number, adopure.Thread>: <extmark_id, pull_request_thread>
    thread_extmarks = {},
}
local Path = require("plenary.path")
local namespace = vim.api.nvim_create_namespace("adopure-marker")

local signs = {
    active = "󰅺 ",
    byDesign = "󱀡 ",
    closed = "󱗡 ",
    fixed = "󰅿 ",
    pending = "󰆄 ",
    unknown = "󰠗 ",
    wontFix = "󰗞 ",
}
---@param bufnr number
---@param pull_request_thread adopure.Thread
---@param context adopure.ThreadContext
local function create_extmark(bufnr, pull_request_thread, context)
    local end_offset = context.rightFileEnd.offset
    local status = pull_request_thread.status
    local hl_group, sign_hl_group = require("adopure.config.internal"):hl_details(status)

    local opts = {
        id = pull_request_thread.id,
        end_row = context.rightFileEnd.line - 1,
        end_col = end_offset - 1,
        hl_group = hl_group,
        sign_hl_group = sign_hl_group,
        sign_text = signs[status],
        hl_eol = false,
    }
    if end_offset == 2147483647 then
        opts.end_row = context.rightFileEnd.line
        opts.end_col = 0
    end
    local start_row = context.rightFileStart.line - 1
    local start_col = context.rightFileStart.offset - 1
    while true do
        local ok, result = pcall(vim.api.nvim_buf_set_extmark, bufnr, namespace, start_row, start_col, opts)
        if not ok then
            local previous_result = ""
            if result == previous_result then
                vim.notify("Failed to add mark for thread; error:" .. tostring(result), 3)
            end

            local invalid_field = vim.split(tostring(result), "'")[2]
            if invalid_field == "end_col" then
                opts.end_col = 0
            end
            if invalid_field == "col" then
                start_col = 0
            end
            if invalid_field == "end_row" then
                opts.end_row = nil
                opts.end_col = nil
            end
            if invalid_field == "line" then
                local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
                start_row = #lines - 1
            end
            previous_result = tostring(result)
            local _ = previous_result
        end
        if ok then
            M.buffer_extmarks[result] = pull_request_thread
            break
        end
    end
end

---@param bufnr number
---@param pull_request_threads adopure.AdoThread[]
function M.clear_removed_comment_marks(bufnr, pull_request_threads)
    local existing_marks = vim.api.nvim_buf_get_extmarks(bufnr, namespace, 0, -1, { details = true })
    vim.iter(existing_marks)
        :filter(function(extmark) ---@param extmark vim.api.keyset.get_extmark_item
            ---@type adopure.AdoThread|nil
            local thread = vim.iter(pull_request_threads)
                :find(function(pull_request_thread) ---@param pull_request_thread adopure.AdoThread
                    return pull_request_thread:match_mark(extmark)
                end)
            return not (thread and thread:is_active_thread())
        end)
        :each(function(extmark) ---@param extmark vim.api.keyset.get_extmark_item
            vim.api.nvim_buf_del_extmark(bufnr, namespace, extmark[1])
        end)
end

---@param bufnr number
---@param state adopure.AdoState
---@param file_path string
function M.create_new_comment_marks(bufnr, state, file_path)
    local focused_file_path = tostring(Path:new(file_path):make_relative(state.root_path))
    local existing_marks = vim.api.nvim_buf_get_extmarks(bufnr, namespace, 0, -1, { details = true })

    vim.iter(state.pull_request_threads)
        :filter(function(thread) ---@param thread adopure.AdoThread
            return thread:should_render_extmark(existing_marks, focused_file_path)
        end)
        :each(function(thread) ---@param thread adopure.AdoThread
            create_extmark(bufnr, thread, thread.threadContext)
        end)
end

---Get extmarks at the cursor position
---@return table<number, number, number>[]: extmark_id, row, col
function M.get_extmarks_at_position()
    local line = vim.api.nvim_win_get_cursor(0)[1] - 1
    return vim.api.nvim_buf_get_extmarks(0, namespace, { line, 0 }, { line + 1, 0 }, {})
end

return M
