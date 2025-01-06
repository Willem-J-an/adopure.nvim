local M = {}

---@private
---@class adopure.CommentCreate
---@field bufnr number
---@field mark_id number
---@field thread_context adopure.ThreadContext
local CommentCreate = {}
M.CommentCreation = CommentCreate

---@param bufnr number
---@param extmark_id number
---@param thread_context adopure.ThreadContext
---@return adopure.CommentCreate
function CommentCreate:new(bufnr, extmark_id, thread_context)
    local o = {
        bufnr = bufnr,
        extmark_id = extmark_id,
        thread_context = thread_context,
    }
    self.__index = self
    return setmetatable(o, self)
end

---@param pull_request adopure.PullRequest
---@param pull_request_thread_context adopure.PullRequestCommentThreadContext
---@param bufnr number
---@return adopure.AdoThread|nil thread, string|nil err
function CommentCreate:submit_thread(pull_request, pull_request_thread_context, bufnr)

    ---@type adopure.NewThread
    local new_thread = {
        threadContext = self.thread_context,
        status = 1,
        pullRequestThreadContext = pull_request_thread_context,
        comments = {
            {
                parentCommentId = 0,
                content = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n"),
                commentType = 1,
            },
        },
    }
    local thread, err = require("adopure.api").create_pull_request_comment_thread(pull_request, new_thread)
    if err or not thread then
        return nil, err or "Expected Thread but got nil;"
    end
    local ado_thread = require("adopure.types.ado_thread").AdoThread:new(thread)
    return ado_thread, nil
end

return M
