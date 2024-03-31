local M = {}
local curl = require("plenary.curl")
local Secret = require("lua.ado.secret")

local API_VERSION = "api-version=7.1-preview.4"
local GIT_API_VERSION = "api-version=7.1-preview.1"

local access_token = Secret.access_token
PROJECT_NAME = ""

local headers = {
    ["Authorization"] = "basic " .. access_token,
    ["Content-Type"] = "application/json",
}

---Get request from azure devops
---@param url string
---@param request_type string
---@return RequestResult result, string err
local function get_azure_devops(url, request_type)
    local ok, response = pcall(curl.request, {
        url = url,
        method = "get",
        headers = headers,
    })
    if not ok or not response or response.status ~= 200 then
        local details = ""
        if response then
            details = response.body
        end
        return {}, "Failed to retrieve " .. request_type .. "; " .. details
    end
    local result = vim.fn.json_decode(response.body)
    return result, ""
end

---Get projects from Azure DevOps
---@return Project[] projects, string err
function M.get_projects()
    local result, err = get_azure_devops(Secret.organization_url .. "_apis/projects?" .. API_VERSION, "projects")

    ---@type Project[]
    local projects = result.value
    return projects, err
end

---Get repository from Azure DevOps
---@param project_name string
---@param repository_name string
---@return Repository repository, string err
function M.get_repository(project_name, repository_name)
    if PROJECT_NAME == "" then
        PROJECT_NAME = project_name
    end
    ---@type Repository
    local repository
    local url = Secret.organization_url .. PROJECT_NAME .. "/_apis/git/repositories?" .. GIT_API_VERSION
    local result, err = get_azure_devops(url, "repositories")

    ---@type Repository[]
    local repositories = result.value
    for _, _repository in pairs(repositories) do
        if _repository.name == repository_name then
            repository = _repository
        end
    end
    return repository, err
end

---Get pull requests from Azure DevOps
---@param repository Repository
---@return Repository repository, string err
function M.get_pull_requests(repository)
    local result, err = get_azure_devops(repository.url .. "/pullrequests?" .. GIT_API_VERSION, "pull requests")

    ---@type PullRequest[]
    local pull_requests = result.value
    return pull_requests, err
end

---Get pull request threads from Azure DevOps
---@param pull_request PullRequest
---@return Thread[] threads, string err
function M.get_pull_requests_threads(pull_request)
    local result, err = get_azure_devops(pull_request.url .. "/threads?" .. GIT_API_VERSION, "pull requests")

    ---@type PullRequest[]
    local pull_requests = result.value
    return pull_requests, err
end

return M
