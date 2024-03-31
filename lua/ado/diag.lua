local M = {}
local Path = require("plenary.path")
---@type Thread[]
M.pull_request_threads = {}
local namespace = vim.api.nvim_create_namespace("ado")
M.diagnostics = {
    {
        bufnr = vim.api.nvim_get_current_buf(),
        lnum = 1,
        end_lnum = 1,
        col = 1,
        end_col = 10,
        severity = 3,
        message = "This is my diag message",
        source = "ado",
        code = "100",
    },
}
vim.diagnostic.set(namespace, 0, diagnostics, {})
local function get_open_file_paths()
    ---@type table<Path, number>
    local open_file_paths = {}
    local buffers = vim.api.nvim_list_bufs()
    for _, buf in pairs(buffers) do
        open_file_paths[Path:new(vim.api.nvim_buf_get_name(buf))] = buf
    end
    return open_file_paths
end

function M.update_diagnostics()
    for _, thread in ipairs(M.pull_request_threads) do
        local open_file_paths = get_open_file_paths()
        local file_path, context
        if thread.threadContext then
            file_path = Path:new(thread.threadContext.filePath)
            context = thread.threadContext
        end
        if file_path and context and open_file_paths[file_path] and thread.threadContext.rightFileStart then
            table.insert(M.diagnostics, {
                bufnr = open_file_paths[file_path],
                lnum = context.rightFileStart.line,
                end_lnum = context.rightFileEnd.line,
                col = context.rightFileStart.offset,
                end_col = context.rightFileEnd.offset,
                severity = 3,
                message = thread.comments[1].content,
                source = "ado",
                code = "100",
            })
        end
    end
end
return M
