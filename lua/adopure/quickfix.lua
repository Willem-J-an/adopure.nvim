---@mod adopure.quickfix
local M = {}

---Render pull request threads in quickfix panel.
---This allows for a workflow of quickly jumping to various comment threads in the code.
---@param pull_request_threads adopure.Thread[]
---@param _ table
function M.render_quickfix(pull_request_threads, _)
    local entries = {}
    for _, pull_request_thread in pairs(pull_request_threads) do
        local file_path, context
        if type(pull_request_thread.threadContext) == "table" then
            local path_reference = pull_request_thread.threadContext.filePath
            file_path = require("plenary.path"):new(string.sub(path_reference, 2))
            context = pull_request_thread.threadContext
        end
        if
            file_path
            and context
            and not pull_request_thread.isDeleted
            and pull_request_thread.threadContext.rightFileStart
        then
            local entry = {
                filename = file_path.filename,
                lnum = vim.F.if_nil(context.rightFileStart.line, 1),
                col = vim.F.if_nil(context.rightFileStart.offset, 1),
                text = "[" .. pull_request_thread.status .. "] - " .. pull_request_thread.comments[1].content,
            }
            table.insert(entries, entry)
        end
    end
    vim.cmd("copen")
    vim.fn.setqflist({}, " ", { nr = "$", items = entries })
end
return M
