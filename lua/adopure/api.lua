local M = {}
local curl = require("plenary.curl")
local config = require("adopure.config.internal")

local GIT_API_VERSION = "api-version=7.1-preview.1"

local access_token = config:access_token()
local organization_url = ""
local project_name = ""

local headers = {
    ["Authorization"] = "basic " .. access_token,
    ["Content-Type"] = "application/json",
}

---Get request from azure devops
---@param url string
---@param request_type string
---@return any|nil result, string|nil err
local function get_azure_devops(url, request_type)
    local ok, response = pcall(curl.request, {
        url = url,
        method = "get",
        headers = headers,
    })
    if not ok or not response or response.status ~= 200 then
        local details = ""
        if response then
            details = response.body or tostring(response)
        end
        return nil, "Failed to retrieve " .. request_type .. "; " .. details
    end
    local result = vim.fn.json_decode(response.body)
    return result, nil
end

---Get repository from Azure DevOps
---@param context adopure.AdoContext
---@return adopure.Repository|nil repository, string|nil err
function M.get_repository(context)
    if organization_url == "" then
        organization_url = context.organization_url
    end
    if project_name == "" then
        project_name = context.project_name
    end
    local url = organization_url .. project_name .. "/_apis/git/repositories?" .. GIT_API_VERSION
    ---@type adopure.RequestResult
    local result, err = get_azure_devops(url, "repositories")
    if not result then
        return nil, err
    end

    ---@type adopure.Repository[]
    local repositories = result.value
    for _, _repository in pairs(repositories) do
        if _repository.name == context.repository_name then
            return _repository, err
        end
    end
end

---Get pull requests from Azure DevOps
---@param repository adopure.Repository
---@return adopure.PullRequest[] pull_requests, string|nil err
function M.get_pull_requests(repository)
    ---@type adopure.RequestResult
    local result, err = get_azure_devops(repository.url .. "/pullrequests?" .. GIT_API_VERSION, "pull requests")
    if not result then
        return {}, err
    end

    ---@type adopure.PullRequest[]
    local pull_requests = result.value
    return pull_requests, err
end

---Get pull request iterations from Azure DevOps
---@param pull_request adopure.PullRequest
---@return adopure.Iteration[] iterations, string|nil err
function M.get_pull_request_iterations(pull_request)
    ---@type adopure.RequestResult
    local result, err =
        get_azure_devops(pull_request.url .. "/iterations?" .. GIT_API_VERSION, "pull request iterations")
    if not result then
        return {}, err
    end

    ---@type adopure.Iteration[]
    local iterations = result.value
    return iterations, err
end

---Get pull request iteration changes from Azure DevOps
---@param pull_request adopure.PullRequest
---@param iteration adopure.Iteration
---@return adopure.ChangeEntry[] change_entries, string|nil err
function M.get_pull_requests_iteration_changes(pull_request, iteration)
    ---@type adopure.ChangeEntries
    local result, err = get_azure_devops(
        pull_request.url .. "/iterations/" .. iteration.id .. "/changes?" .. GIT_API_VERSION,
        "pull request iteration changes"
    )
    if not result then
        return {}, err
    end

    return result.changeEntries, err
end

---Get not deleted pull request threads from Azure DevOps
---@param state adopure.AdoState
---@return adopure.Thread[] threads, string|nil err
function M.get_pull_request_threads(state)
    local iteration = "$baseIteration=1&iteration=" .. state.active_pull_request_iteration.id
    ---@type adopure.RequestResult
    local result, err = get_azure_devops(
        state.active_pull_request.url .. "/threads?" .. table.concat({ GIT_API_VERSION, iteration }, "&"),
        "pull request threads"
    )
    if not result then
        return {}, err
    end

    ---@type adopure.Thread[]
    local threads = result.value
    local active_threads = vim.iter(threads)
        :filter(function(thread) ---@param thread adopure.Thread
            return not thread.isDeleted
        end)
        :totable()
    return active_threads, err
end

---patch request to azure devops
---@param url string
---@param request_type string
---@return any|nil result, string|nil err
local function submit_azure_devops(url, http_verb, request_type, body)
    local ok, response = pcall(curl.request, {
        url = url,
        method = http_verb,
        headers = headers,
        body = vim.fn.json_encode(body),
    })
    if not ok or not response or response.status ~= 200 then
        local details = ""
        if response then
            details = response.body or tostring(response)
        end
        return nil, "Failed to " .. http_verb .. " " .. request_type .. "; " .. details
    end
    if type(response.body) == "string" and #response.body ~=0 then
        ---@type adopure.Thread|adopure.Comment|adopure.Reviewer|nil
        local result = vim.fn.json_decode(response.body)
        return result, nil
    end
    return nil, nil
end

---Create new pull request comment thread
---@param pull_request adopure.PullRequest
---@param new_thread adopure.NewThread
---@return adopure.Thread|nil thread, string|nil err
function M.create_pull_request_comment_thread(pull_request, new_thread)
    ---@type adopure.Thread|nil
    local result, err = submit_azure_devops(
        pull_request.url .. "/threads?" .. GIT_API_VERSION,
        "POST",
        "pull request thread",
        new_thread
    )

    return result, err
end

---Create new pull request comment reply
---@param pull_request adopure.PullRequest
---@param thread adopure.Thread
---@param comment adopure.NewComment
---@return adopure.Comment|nil comment, string|nil err
function M.create_pull_request_comment_reply(pull_request, thread, comment)
    ---@type adopure.Comment|nil
    local result, err = submit_azure_devops(
        pull_request.url .. "/threads/" .. thread.id .. "/comments?" .. GIT_API_VERSION,
        "POST",
        "pull request comment reply",
        comment
    )

    return result, err
end

---Create new pull request comment reply
---@param pull_request adopure.PullRequest
---@param thread adopure.Thread
---@return adopure.Thread|nil thread, string|nil err
function M.update_pull_request_thread(pull_request, thread)
    ---@type adopure.Thread|nil
    local result, err = submit_azure_devops(
        pull_request.url .. "/threads/" .. thread.id .. "?" .. GIT_API_VERSION,
        "PATCH",
        "pull request thread update",
        thread
    )
    return result, err
end

---Create new pull request comment reply
---@param pull_request adopure.PullRequest
---@param thread adopure.Thread
---@param comment_id number
---@return adopure.Thread|nil thread, string|nil err
function M.delete_pull_request_comment(pull_request, thread, comment_id)
    ---@type adopure.Thread|nil
    local result, err = submit_azure_devops(
        table.concat({ pull_request.url, "/threads/", thread.id, "/comments/", comment_id, "?", GIT_API_VERSION }),
        "DELETE",
        "pull request thread update",
        nil
    )
    return result, err
end

---Create new pull request vote
---@param pull_request adopure.PullRequest
---@param vote PullRequestVote
---@return adopure.Reviewer|nil reviewer, string|nil err
function M.submit_vote(pull_request, vote)
    ---@type adopure.ConnectionData
    local connection_result, connection_err =
        get_azure_devops(organization_url .. "/_apis/connectionData", "connectionData")
    if connection_err then
        return nil, connection_err
    end

    local reviewer_id = connection_result.authenticatedUser.id

    ---@type adopure.Reviewer|nil
    local result, err = submit_azure_devops(
        pull_request.url .. "/reviewers/" .. reviewer_id .. "?" .. GIT_API_VERSION,
        "PUT",
        "pull request thread update",
        { vote = vote, id = reviewer_id }
    )
    return result, err
end

return M
