local M = {}
--- Await result of plenary job
---@param job Job
---@return unknown
function M.await_result(job)
    local result
    while true do
        if result then
            return result
        end
        vim.wait(1000, function()
            ---@diagnostic disable-next-line: missing-return
            result = job:result()[1]
        end)
    end
end

return M
