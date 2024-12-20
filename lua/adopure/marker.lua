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
            local invalid_field = vim.split(result, "'")[2]
            if invalid_field == "end_col" and opts.end_col ~= 0 then
                opts.end_col = 0
                break
            end
            if invalid_field == "col" and start_col ~= 0 then
                start_col = 0
                local _ = start_col -- fix incorrect unignorable warning
                break
            end
            break
        end
        if ok then
            M.buffer_extmarks[result] = pull_request_thread
            break
        end
    end
end

---Create extmarks for pull request threads
---@param pull_request_threads adopure.Thread[]
---@param bufnr number
---@param file_path string
function M.create_buffer_extmarks(pull_request_threads, bufnr, file_path)
    vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)

    local focused_file_path = tostring(Path:new(file_path):make_relative())
    for _, pull_request_thread in ipairs(pull_request_threads) do
        local context
        if type(pull_request_thread.threadContext) == "table" then
            local path_reference = pull_request_thread.threadContext.filePath
            file_path = tostring(Path:new(string.sub(path_reference, 2)))
            context = pull_request_thread.threadContext
        end

        if
            file_path
            and context
            and focused_file_path == file_path
            and not pull_request_thread.isDeleted
            and pull_request_thread.threadContext.rightFileStart
        then
            create_extmark(bufnr, pull_request_thread, context)
        end
    end
end

---Get extmarks at the cursor position
---@return table<number, number, number>[]: extmark_id, row, col
function M.get_extmarks_at_position()
    local line = vim.api.nvim_win_get_cursor(0)[1] - 1
    local buffer_marks = vim.api.nvim_buf_get_extmarks(0, namespace, { line, 0 }, { line + 1, 0 }, {})
    return buffer_marks
end

return M
