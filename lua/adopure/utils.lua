local M = {}
---@class adopure.JobResult
---@field stdout string[]
---@field stderr string[]

--- Await result of plenary job
---@diagnostic disable-next-line: undefined-doc-name
---@param job Job
---@return adopure.JobResult
function M.await_result(job)
    local stdout, stderr
    while true do
        if (stdout and stdout[1]) or (stderr and stderr[1]) then
            return {
                stdout = stdout,
                stderr = stderr,
            }
        end
        vim.wait(200, function()
            ---@diagnostic disable-next-line: missing-return,undefined-field
            stdout = job:result()
            ---@diagnostic disable-next-line: missing-return,undefined-field
            stderr = job:stderr_result()
        end)
    end
end

return M
