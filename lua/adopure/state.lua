---@class adopure.AdoContext
---@field organization_url string
---@field project_name string
---@field repository_name string
local AdoContext = {}
---@return adopure.AdoContext
function AdoContext:new()
    local organization_url, project_name, repository_name = require("adopure.git").get_remote_config()
    local o = {
        organization_url = organization_url,
        project_name = project_name,
        repository_name = repository_name,
    }
    self.__index = self
    return setmetatable(o, self)
end

---@class adopure.AdoState
---@field repository adopure.Repository
---@field active_pull_request adopure.PullRequest
---@field active_pull_request_iteration adopure.Iteration
---@field pull_request_threads adopure.Thread[]
---@field comment_creations adopure.CommentCreate[]
---@field comment_replies adopure.CommentReply[]
local AdoState = {}

---@param repository adopure.Repository
---@param pull_request adopure.PullRequest
---@return adopure.AdoState
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
    local iterations, err = require("adopure.api").get_pull_request_iterations(self.active_pull_request)
    if err then
        error(err)
    end
    self.active_pull_request_iteration = iterations[#iterations]
end

---@param _ table
function AdoState:load_pull_request_threads(_)
    local pull_request_threads, err = require("adopure.api").get_pull_request_threads(self)
    if err then
        error(err)
    end
    self.pull_request_threads = pull_request_threads
end

---@class adopure.StateManager
---@field repository adopure.Repository
---@field pull_requests adopure.PullRequest[]
---@field state adopure.AdoState|nil
local StateManager = {}

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
    }
    self.__index = self
    return setmetatable(o, self)
end

---@param _ table
function StateManager:choose_and_activate(_)
    require("adopure.pickers.pull_request").choose_and_activate(self)
end

---@param pull_request adopure.PullRequest
function StateManager:set_state_by_choice(pull_request)
    self.state = require("adopure.state").AdoState:new(self.repository, pull_request)
end

return {
    AdoContext = AdoContext,
    AdoState = AdoState,
    StateManager = StateManager,
}
