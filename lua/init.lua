local Git = require("lua.ado.git")
local Api = require("lua.ado.api")
local Path = require("plenary.path")
local Config = require("lua.ado.config")
local Util = require("lua.ado.utils")
local Project = require("lua.ado.project")
local Diag = require("lua.ado.diag")

local repository_name = Git.get_repo_name()
repository_name = "rmg-lakehouse"
local project_name = Project.get_project_name(repository_name)
if not project_name then
    error("No project name set yet;")
end

local repository, err
repository, err = Api.get_repository(project_name, repository_name)
if err ~= "" then
    error(err)
end

local pull_requests
pull_requests, err = Api.get_pull_requests(repository)
if err ~= "" then
    error(err)
end

local pull_request_choices = {}
for index, pull_request in pairs(pull_requests) do
    table.insert(pull_request_choices, index .. ": " .. pull_request.title)
end
vim.ui.select(pull_request_choices, { prompt = "Select Azure DevOps pull request" }, function(choice)
    local index = vim.split(choice, ":")[1]
    ---@type PullRequest
    local pull_request = pull_requests[tonumber(index)]
	---@type Thread[]
	local pull_request_threads
	pull_request_threads, err = Api.get_pull_requests_threads(pull_request)

    if err ~= "" then
        error(err)
    end
    Diag.pull_request_threads = pull_request_threads
    Diag.update_diagnostics()
end)
