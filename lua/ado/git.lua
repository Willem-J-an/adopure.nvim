local M = {}

---Get git repository name
---@return string Repository name
function M.get_repo_name()
    local get_git_repo_job = require("plenary.job"):new({
        command = "git",
        args = { "rev-parse", "--show-toplevel" },
        cwd = ".",
    })
    get_git_repo_job:start()

    local repository_path = require("plenary.path"):new(require("ado.utils").await_result(get_git_repo_job))
    local path_parts = vim.split(repository_path.filename, repository_path.path.sep)
    return path_parts[#path_parts]
end

---@param pull_request PullRequest
---@param open_callable function
function M.confirm_checkout_and_open(pull_request, open_callable)
    local Job = require("plenary.job")
    vim.ui.input({ prompt = "Try to checkout pull request source branch? <CR> / <ESC>" }, function(input)
        if not input then
            open_callable()
            return
        end
        local remote_source_name = "origin/" .. vim.split(pull_request.sourceRefName, "refs/heads/")[2]

        local git_checkout_remote_job = Job:new({
            command = "git",
            args = { "checkout", remote_source_name },
            cwd = ".",
            on_exit = function(j, return_val)
                if return_val ~= 0 then
                    error("Checkout failed: " .. vim.inspect(j:result()))
                end
            end,
        })

        local remote_target_name = "origin/" .. vim.split(pull_request.targetRefName, "refs/heads/")[2]
        local git_rebase_abort_job = Job:new({
            command = "git",
            args = { "rebase", "--abort" },
            cwd = ".",
            on_exit = function(j, return_val)
                if return_val ~= 0 then
                    error("Rebase abort failed: " .. vim.inspect(j:result()))
                end
            end,
        })
        local git_rebase_job = Job:new({
            command = "git",
            args = { "rebase", remote_target_name },
            cwd = ".",
            on_exit = function(j, return_val)
                if return_val ~= 0 then
                    git_rebase_abort_job:start()
                    error("Rebase failed: " .. vim.inspect(j:result()))
                end
            end,
        })
        git_checkout_remote_job:and_then_on_success(git_rebase_job)
        git_checkout_remote_job:start()
        open_callable()
    end)
end

return M
