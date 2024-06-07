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

    local repository_path = require("plenary.path"):new(require("ado.utils").await_result(get_git_repo_job)[1])
    local path_parts = vim.split(repository_path.filename, repository_path.path.sep)
    return path_parts[#path_parts]
end

---@param remote_url string
---@return string organization_url
---@return string project_name
---@return string repository_name
local function extract_git_details(remote_url)
    local organization_url, project_name, repository_name
    if remote_url:find("@ssh.dev.azure.com") then
        local _, _, base_url, org_name, project_name_extracted, repo_name_extracted =
            remote_url:find(".-@(ssh.dev.azure.com):v3/(.-)/(.-)/(.+)%s*%(fetch%)")
        organization_url = "https://" .. base_url:gsub("ssh.", "") .. "/" .. org_name
        project_name = project_name_extracted
        repository_name = repo_name_extracted
    elseif remote_url:find("https") then
        local https_pattern = "(https://)[^@]*@([^/]+)/([^/]+)/([^/]+)/_git/([^%s]+)"
        local _, _, protocol, domain, org_name, project_name_extracted, repo_name_extracted =
            remote_url:find(https_pattern)
        organization_url = protocol .. domain .. "/" .. org_name
        project_name = project_name_extracted
        repository_name = repo_name_extracted
    end

    local trim_pattern = "^%s*(.-)%s*$"
    return organization_url:gsub(trim_pattern, "%1") .. "/",
        project_name:gsub(trim_pattern, "%1"),
        repository_name:gsub(trim_pattern, "%1")
end

---Get config from git remote
---@return string organization_url
---@return string project_name
---@return string repository_name
function M.get_remote_config()
    local get_remotes = require("plenary.job"):new({
        command = "git",
        args = { "remote", "-v" },
        cwd = ".",
    })
    get_remotes:start()
    ---@type string
    local remote = require("ado.utils").await_result(get_remotes)[1]
    return extract_git_details(remote)
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
