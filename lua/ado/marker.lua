local M = {
    ---@type table<number, Thread>: <extmark_id, pull_request_thread>
    buffer_extmarks = {},
    ---@type table<number, Thread>: <extmark_id, pull_request_thread>
    thread_extmarks = {},
}
local Path = require("plenary.path")

---Get open file paths with bufnrs
---@return table<Path, number>
local function get_open_file_paths()
    ---@type table<Path, number>
    local open_file_paths = {}
    local buffers = vim.api.nvim_list_bufs()
    for _, buf in pairs(buffers) do
        local buffer_path = vim.api.nvim_buf_get_name(buf)
        open_file_paths[Path:new(buffer_path):absolute()] = buf
    end
    return open_file_paths
end
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
---@param namespace number
---@param pull_request_thread Thread
---@param context ThreadContext
local function create_extmark(bufnr, namespace, pull_request_thread, context)
    local end_offset = context.rightFileEnd.offset
    local status = pull_request_thread.status
    local hl_group, sign_hl_group

    if status == "active" or status == "pending" then
        hl_group = "AdoPrActive"
        sign_hl_group = "@comment.todo"
    else
        hl_group = "AdoPrClosed"
        sign_hl_group = "@comment.note"
    end
    local opts = {
        id = pull_request_thread.id,
        end_row = context.rightFileEnd.line - 1,
        end_col = end_offset - 1,
        hl_group = hl_group,
        sign_hl_group = sign_hl_group,
        sign_text = signs[status],
    }
    if end_offset == 2147483647 then
        opts["end_col"] = nil
    end
    local extmark = vim.api.nvim_buf_set_extmark(
        bufnr,
        namespace,
        context.rightFileStart.line - 1,
        context.rightFileStart.offset - 1,
        opts
    )
    M.buffer_extmarks[extmark] = pull_request_thread
end

---Create extmarks for pull request threads
---@param namespace number
---@param pull_request_threads Thread[]
function M.create_buffer_extmarks(namespace, pull_request_threads)
    local focused_file_path = Path:new(vim.fn.expand("%:."))
    for _, pull_request_thread in ipairs(pull_request_threads) do
        local open_file_paths = get_open_file_paths()
        local file_path, context
        if type(pull_request_thread.threadContext) == "table" then
            local path_reference = pull_request_thread.threadContext.filePath
            file_path = Path:new(string.sub(path_reference, 2))
            context = pull_request_thread.threadContext
        end
        if
            file_path
            and context
            and tostring(focused_file_path.filePath) == tostring(file_path.filePath)
            and not pull_request_thread.isDeleted
            and open_file_paths[file_path:absolute()]
            and pull_request_thread.threadContext.rightFileStart
        then
            --- Due to a bug in azure devops rest api; creating extmarks may fail for incorrect positions;
            ---https://developercommunity.visualstudio.com/t/Pull-Request-Threads---List-API-operatio/10628358
            pcall(create_extmark, open_file_paths[file_path:absolute()], namespace, pull_request_thread, context)
        end
    end
end

---Get extmarks at the cursor position
---@return table<number, number, number>[]: extmark_id, row, col
function M.get_extmarks_at_position(namespace)
    local line = vim.api.nvim_win_get_cursor(0)[1] - 1
    local buffer_marks = vim.api.nvim_buf_get_extmarks(0, namespace, { line, 0 }, { line + 1, 0 }, {})
    return buffer_marks
end

return M
