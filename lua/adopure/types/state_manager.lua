---@mod adopure.types.state_manager
local M = {}

---@private
---@class adopure.AdoContext
---@field organization_url string
---@field project_name string
---@field repository_name string
---@field root_path string
local AdoContext = {}
M.AdoContext = AdoContext

---@return adopure.AdoContext
function AdoContext:new()
    local organization_url, project_name, repository_name, root_path = require("adopure.git").get_remote_config()
    local o = {
        organization_url = organization_url,
        project_name = project_name,
        repository_name = require("adopure.utils").url_decode(repository_name),
        root_path = root_path,
    }
    self.__index = self
    return setmetatable(o, self)
end

---@class adopure.StateManager
---@field repository adopure.Repository
---@field pull_requests adopure.PullRequest[]
---@field state adopure.AdoState|nil
---@field root_path string
local StateManager = {}
M.StateManager = StateManager

---@param context adopure.AdoContext
function StateManager:new(context)
    local repository, repository_err = require("adopure.api").get_repository(context)
    if repository_err then
        error(repository_err)
    end
    assert(repository, "No repository with correct name found in project;")
    local pull_requests, pull_request_err = require("adopure.api").get_pull_requests(repository)
    if pull_request_err then
        error(pull_request_err)
    end

    local o = {
        repository = repository,
        pull_requests = pull_requests,
        state = nil,
        root_path = context.root_path,
    }
    self.__index = self
    self = setmetatable(o, self)
    return self
end

---Prompt to choose a PR and activate the context.
---@param _ table
function StateManager:choose_and_activate(_)
    require("adopure.pickers.pull_request").choose_and_activate(self)
end

---@param pull_request adopure.PullRequest
function StateManager:set_state_by_choice(pull_request)
    self.state = require("adopure.types.ado_state").AdoState:new(self.repository, pull_request, self.root_path)
end

---@export AdoState, StateManager
return M
