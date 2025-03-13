---@mod adopure.types.state
local M = {}
---@private
---@class adopure.AdoState
---@field user adopure.ConnectionUser
---@field repository adopure.Repository
---@field active_pull_request adopure.PullRequest
---@field active_pull_request_iteration adopure.Iteration
---@field pull_request_threads adopure.AdoThread[]
---@field comment_creations adopure.CommentCreate[]
---@field comment_replies adopure.CommentReply[]
---@field root_path string
local AdoState = {}
M.AdoState = AdoState

---@param repository adopure.Repository
---@param pull_request adopure.PullRequest
---@return adopure.AdoState
---@see adopure.load_state_manager
function AdoState:new(repository, pull_request, root_path)
    local o = {
        user = self.load_connection_data().authorizedUser,
        repository = repository,
        active_pull_request = pull_request,
        active_pull_request_iteration = nil,
        pull_request_threads = nil,
        comment_creations = {},
        comment_replies = {},
        root_path = root_path,
    }
    self.__index = self
    self = setmetatable(o, self)
    self:load_pull_request_iterations()
    self:load_pull_request_threads({})
    return self
end

---@private
function AdoState:load_pull_request_iterations()
    local iterations, err = require("adopure.api").get_pull_request_iterations(self.active_pull_request)
    if err then
        error(err)
    end
    self.active_pull_request_iteration = iterations[#iterations]
end

---@private
---@return adopure.ConnectionData
function AdoState.load_connection_data()
    local result, err = require("adopure.api").get_connection_data()
    if err or not result then
        error(err or "Failed to retrieve connection data;")
    end
    return result
end

---Fetch comment threads from Azure DevOps.
---Comment threads are added upon initialization and when creating new threads with the plugin.
---Comment threads created by others, or without the plugin are not automatically loaded.
---@param _ table
function AdoState:load_pull_request_threads(_)
    local pull_request_threads, err = require("adopure.api").get_pull_request_threads(self)
    if err then
        error(err)
    end
    self.pull_request_threads = vim.iter(pull_request_threads)
        :map(function(thread) ---@param thread adopure.Thread
            local new_thread = require("adopure.types.ado_thread").AdoThread:new(thread)
            new_thread.is_changed = true
            return new_thread
        end)
        :totable()
end

---@param bufnr number
---@return adopure.CommentReply|nil
function AdoState:get_comment_reply(bufnr)
    ---@type adopure.CommentReply|nil
    local comment_reply = vim.iter(self.comment_replies)
        :find(function(comment_reply) ---@param comment_reply adopure.CommentReply
            return comment_reply.bufnr == bufnr
        end)
    return comment_reply
end

---@param bufnr number
---@return adopure.CommentCreate|nil
function AdoState:get_comment_creation(bufnr)
    return vim.iter(self.comment_creations)
        :find(function(comment_creation) ---@param comment_creation adopure.CommentCreate
            return comment_creation.bufnr == bufnr
        end)
end

---@param bufnr number
---@param mark_id number
---@param thread_to_open adopure.AdoThread
function AdoState:add_comment_reply(bufnr, mark_id, thread_to_open)
    local comment_reply = require("adopure.types.comment_reply").CommentReply:new(bufnr, mark_id, thread_to_open)
    table.insert(self.comment_replies, comment_reply)
end

---@param comment_creation adopure.CommentCreate
function AdoState:clear_comment_creation(comment_creation)
    self.comment_creations = vim.iter(self.comment_creations)
        :filter(function(state_comment_creation) ---@param state_comment_creation adopure.CommentCreate
            return comment_creation.bufnr ~= state_comment_creation.bufnr
        end)
        :totable()
end

---Submit a new comment thread or reply to an existing one.
---Can be called in a new thread window, or in an existing thread window.
---@param _ table
function AdoState:submit_comment(_)
    ---@type string|nil
    local err
    local bufnr = vim.api.nvim_get_current_buf()
    local comment_creation = self:get_comment_creation(bufnr)
    if comment_creation then
        local comment_thread_context, get_err = self:get_comment_thread_context(comment_creation.thread_context)

        if get_err or not comment_thread_context then
            error(get_err or "Expected PullRequestCommentThreadContext but got nil;")
        end
        local thread, submit_err =
            comment_creation:submit_thread(self.active_pull_request, comment_thread_context, bufnr)
        if submit_err or not thread then
            error(submit_err or "Expected thread but got nil")
        end

        table.insert(self.pull_request_threads, thread)
        local render_bufnr, mark_id = thread:render_reply_thread()
        self:add_comment_reply(render_bufnr, mark_id, thread)
        self:clear_comment_creation(comment_creation)
        return
    end

    local comment_reply = self:get_comment_reply(bufnr)
    if comment_reply then
        err = comment_reply:submit(self.active_pull_request, bufnr)
        if err then
            error(err)
        end
        return
    end
    vim.notify("No comment found to create or reply to;", 3)
end

---@param thread_context adopure.ThreadContext
---@return adopure.PullRequestCommentThreadContext|nil pull_request_thread_context, string|nil err
function AdoState:get_comment_thread_context(thread_context)
    local iteration_changes, err = require("adopure.api").get_pull_requests_iteration_changes(
        self.active_pull_request,
        self.active_pull_request_iteration
    )
    if err then
        return nil, err
    end
    local iteration_change = vim.iter(iteration_changes):find(function(change) ---@param change adopure.ChangeEntry
        return change.item.path == thread_context.filePath
    end)
    if not iteration_change then
        return iteration_change, "File not changed in this Pull Request;"
    end

    ---@type adopure.PullRequestCommentThreadContext
    local comment_thread_context = {
        changeTrackingId = iteration_change.changeTrackingId,
        iterationContext = {
            firstComparingIteration = self.active_pull_request_iteration.id,
            secondComparingIteration = self.active_pull_request_iteration.id,
        },
    }
    return comment_thread_context, nil
end

---Update pull request thread.
---Will prompt the user to supply the requested new state.
---Can be called in an existing thread window.
---@param opts adopure.UpdateThreadOpts
function AdoState:update_thread(opts)
    ---@type number
    local bufnr = vim.api.nvim_get_current_buf()
    local comment_reply = self:get_comment_reply(bufnr)
    if not comment_reply then
        vim.notify("No comment reply found;", 3)
        return
    end

    comment_reply:update(opts.target, self.active_pull_request, self.user.id)
end

return M
