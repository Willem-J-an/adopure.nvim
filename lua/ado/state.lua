---@class AdoContext
---@field organization_url string
---@field project_name string
---@field repository_name string
local AdoContext = {}
---@return AdoContext
function AdoContext:new()
    local organization_url, project_name, repository_name = require("ado.git").get_remote_config()
    local o = {
        organization_url = organization_url,
        project_name = project_name,
        repository_name = repository_name,
    }
    self.__index = self
    return setmetatable(o, self)
end

---@class AdoState
---@field repository Repository
---@field active_pull_request PullRequest
---@field active_pull_request_iteration Iteration
---@field pull_request_threads Thread[]
---@field comment_creations CommentCreate[]
---@field comment_replies CommentReply[]
local AdoState = {}

---@param repository Repository
---@param pull_request PullRequest
---@return AdoState
function AdoState:new(repository, pull_request)
    local o = {
        repository = repository,
        active_pull_request = pull_request,
        active_pull_request_iteration = nil,
        pull_request_threads = nil,
        comment_creations = {},
        comment_replies = {},
    }
    self.__index = self
    self = setmetatable(o, self)
    self:load_pull_request_iterations()
    self:load_pull_request_threads({})
    return self
end

function AdoState:load_pull_request_iterations()
    local iterations, err = require("ado.api").get_pull_request_iterations(self.active_pull_request)
    if err then
        error(err)
    end
    self.active_pull_request_iteration = iterations[#iterations]
end

---@param _ table
function AdoState:load_pull_request_threads(_)
    local pull_request_threads, err = require("ado.api").get_pull_request_threads(self)
    if err then
        error(err)
    end
    self.pull_request_threads = pull_request_threads
end

---@class StateManager
---@field repository Repository
---@field pull_requests PullRequest[]
---@field state AdoState|nil
local StateManager = {}

---@param context AdoContext
function StateManager:new(context)
    local repository, repository_err = require("ado.api").get_repository(context)
    if repository_err then
        error(repository_err)
    end
    assert(repository, "No repository with correct name found in project;")
    local pull_requests, pull_request_err = require("ado.api").get_pull_requests(repository)
    if pull_request_err then
        error(pull_request_err)
    end
    local o = {
        repository = repository,
        pull_requests = pull_requests,
        state = nil,
    }
    self.__index = self
    return setmetatable(o, self)
end

---@param _ table
function StateManager:choose_and_activate(_)
    require("ado.pickers.pull_request").choose_and_activate(self)
end

---@param pull_request PullRequest
function StateManager:set_state_by_choice(pull_request)
    self.state = require("ado.state").AdoState:new(self.repository, pull_request)
end

return {
    AdoContext = AdoContext,
    AdoState = AdoState,
    StateManager = StateManager,
}
