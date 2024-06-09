local M = {}
--- Await result of plenary job
---@diagnostic disable-next-line: undefined-doc-name
---@param job Job
---@return unknown
function M.await_result(job)
    local result
    while true do
        if result then
            return result
        end
        vim.wait(1000, function()
            ---@diagnostic disable-next-line: missing-return,undefined-field
            result = job:result()
        end)
    end
end

return M
