local M = {}

---@param remote_stdout string[]
---@return string remote
local function elect_remote(remote_stdout)
    local preferred_remotes = require("adopure.config.internal").preferred_remotes
    for _, remote_line in ipairs(remote_stdout) do
        local name_and_details = vim.split(remote_line, "\t")
        local remote_name = name_and_details[1]
        if vim.tbl_contains(preferred_remotes, remote_name) then
            return remote_line
        end
    end
    for _, remote_line in ipairs(remote_stdout) do
        if remote_line:find("azure.com") or remote_line:find("visualstudio.com") then
            return remote_line
        end
    end
    vim.notify("adopure unable to elect azure devops remote url; taking the first", 3)
    return remote_stdout[1]
end

---@param remote_stdout string
---@param root_path string
---@return string organization_url
---@return string project_name
---@return string repository_name
---@return string root_path
local function extract_git_details(remote_stdout, root_path)
    local host, project_name, repository_name, organization_name
    local url_with_type = vim.split(remote_stdout, "\t")[2]
    local url = vim.split(url_with_type, " ")[1]
    if url:find("@ssh") then
        local ssh_base
        ssh_base, organization_name, project_name, repository_name = unpack(vim.split(url, "/"))
        host = vim.split(vim.split(ssh_base, ":")[1], "@ssh.")[2]
    end
    if remote_stdout:find("https://") then
        local https_base, user_domain
        https_base, repository_name = unpack(vim.split(url, "/_git/"))
        user_domain, organization_name, project_name = unpack(vim.split(https_base, "/"), 3)
        local user_at_host_parts = vim.split(user_domain, "@")
        host = user_at_host_parts[#user_at_host_parts]
    end
    local organization_url = table.concat({ "https://", host, "/", organization_name, "/" })
    return organization_url, project_name, repository_name, root_path
end

---Get config from git remote
---@return string organization_url
---@return string project_name
---@return string repository_name
---@return string root_path
function M.get_remote_config()
    local get_remotes = require("plenary.job"):new({ ---@diagnostic disable-line: missing-fields
        command = "git",
        args = { "remote", "-v" },
        cwd = ".",
    })
    local get_root = require("plenary.job"):new({ ---@diagnostic disable-line: missing-fields
        command = "git",
        args = { "rev-parse", "--show-toplevel" },
        cwd = ".",
    })

    get_remotes:start()
    get_root:start()
    local remote_result = require("adopure.utils").await_result(get_remotes)
    local root_result = require("adopure.utils").await_result(get_root)
    vim.iter({ remote_result, root_result })
        :filter(function(result) ---@param result adopure.JobResult
            return not not result.stderr[1]
        end)
        :each(function(result) ---@param result adopure.JobResult
            if not result.stdout[1] then
                error(result.stderr[1])
            end
            vim.notify(result.stderr[1], 3)
        end)
    assert(remote_result.stdout[1], "No remote found to extract details;")
    assert(root_result.stdout[1], "No root location found in repo;")
    local elected_remote = elect_remote(remote_result.stdout)
    return extract_git_details(elected_remote, root_result.stdout[1])
end

---Get merge base commit
---@param pull_request adopure.PullRequest
---@return string merge_base
function M.get_merge_base(pull_request)
    local get_merge_base = require("plenary.job"):new({ ---@diagnostic disable-line: missing-fields
        command = "git",
        args = {
            "merge-base",
            pull_request.lastMergeSourceCommit.commitId,
            pull_request.lastMergeTargetCommit.commitId,
        },
        cwd = ".",
    })
    get_merge_base:start()
    local result = require("adopure.utils").await_result(get_merge_base)
    if result.stderr[1] then
        if not result.stdout[1] then
            error(result.stderr[1])
        end
        vim.notify(result.stderr[1], 3)
    end
    assert(result.stdout[1], "No merge base found;")
    return result.stdout[1]
end

---@param pull_request adopure.PullRequest
---@param open_callable function
function M.confirm_checkout_and_open(pull_request, open_callable)
    local Job = require("plenary.job")
    vim.ui.input({ prompt = "Try to checkout pull request source branch? <CR> / <ESC>" }, function(input)
        if not input then
            open_callable()
            return
        end
        local git_checkout_remote_job = Job:new({ ---@diagnostic disable-line: missing-fields
            command = "git",
            args = { "checkout", pull_request.lastMergeSourceCommit.commitId },
            cwd = ".",
            on_exit = function(j, return_val)
                if return_val ~= 0 then
                    error("Checkout failed: " .. vim.inspect(j:result()))
                end
            end,
        })

        git_checkout_remote_job:start()
        open_callable()
    end)
end

return M
