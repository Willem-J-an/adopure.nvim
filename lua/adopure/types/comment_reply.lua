local M = {}

---@private
---@class adopure.CommentReply
---@field bufnr number
---@field mark_id number
---@field thread adopure.AdoThread
local CommentReply = {}
M.CommentReply = CommentReply

---@param bufnr number
---@param extmark_id number
---@param thread adopure.AdoThread
---@return adopure.CommentReply
function CommentReply:new(bufnr, extmark_id, thread)
    local o = {
        bufnr = bufnr,
        extmark_id = extmark_id,
        thread = thread,
    }
    self.__index = self
    return setmetatable(o, self)
end

local thread_status = {
    "active",
    "byDesign",
    "closed",
    "fixed",
    "pending",
    "unknown",
    "wontFix",
}

---@param target adopure.UpdateThreadTarget
---@param pull_request adopure.PullRequest
---@param user_id string
function CommentReply:update(target, pull_request, user_id)
    local targets = {
        delete_comment = self.delete_comment,
        edit_comment = self.edit_comment,
        update_status = self.update_status,
    }
    targets[target](self, pull_request, user_id)
end

---@param pull_request adopure.PullRequest
---@param _ string
function CommentReply:update_status(pull_request, _)
    vim.ui.select(thread_status, { prompt = "Select new status;" }, function(choice)
        if not choice then
            vim.notify("No new status chosen;", 3)
            return
        end

        ---@type adopure.Thread
        local thread = { ---@diagnostic disable-line: missing-fields
            id = self.thread.id,
            status = choice,
        }
        local updated_thread, err = require("adopure.api").update_pull_request_thread(pull_request, thread)
        if err or not updated_thread then
            error(err or "Expected Thread but not nil;")
        end
        self.thread.status = updated_thread.status
        self.thread:render_reply_thread()
        self.thread.is_changed = true
    end)
end

---@param pull_request adopure.PullRequest
---@param user_id string
function CommentReply:delete_comment(pull_request, user_id)
    vim.ui.select(self:active_own_comments(user_id), {
        prompt = "Select comment to delete...",
        format_item = function(comment) ---@param comment adopure.Comment
            return comment.content
        end,
    }, function(comment) ---@param comment adopure.Comment
        if not comment then
            vim.notify("No comment selected;")
            return
        end
        local _, err = require("adopure.api").delete_pull_request_comment(pull_request, self.thread, comment.id)
        if err then
            error(err)
        end
        comment.isDeleted = true

        if self.thread:is_active_thread() then
            self.thread:render_reply_thread()
            return
        end

        vim.api.nvim_buf_delete(0, { force = true })
    end)
end

---@private
---@param user_id string
---@return adopure.Comment[]
function CommentReply:active_own_comments(user_id)
    return vim.iter(self.thread.comments)
        :filter(function(comment) ---@param comment adopure.Comment
            return comment.author.id == user_id and not comment.isDeleted
        end)
        :totable()
end

---@param pull_request adopure.PullRequest
---@param user_id string
function CommentReply:edit_comment(pull_request, user_id)
    ---@param comment adopure.Comment|nil
    local function rewrite_and_update(comment)
        if not comment then
            vim.notify("No comment selected;")
            return
        end
        ---@param input string|nil
        local function update_comment(input)
            if not input then
                vim.notify("No new comment content;")
                return
            end
            ---@type adopure.Comment
            local updated_comment = { ---@diagnostic disable-line: missing-fields
                id = comment.id,
                content = input,
            }
            local _, err =
                require("adopure.api").update_pull_request_comment(pull_request, self.thread, updated_comment)
            if err then
                error(err)
            end
            comment.content = input
            self.thread:render_reply_thread()
        end
        vim.ui.input({ prompt = "Edit the comment;", default = comment.content }, update_comment)
    end

    vim.ui.select(self:active_own_comments(user_id), {
        prompt = "Select the comment to edit",
        format_item = function(comment) ---@param comment adopure.Comment
            return comment.content
        end,
    }, rewrite_and_update)
end

---@param pull_request adopure.PullRequest
---@param bufnr number
function CommentReply:submit(pull_request, bufnr)
    local comments = self.thread.comments

    ---@type adopure.NewComment
    local new_reply = {
        parentCommentId = comments[#comments].id - 1,
        content = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n"),
        commentType = 1,
    }
    local comment, err = require("adopure.api").create_pull_request_comment_reply(pull_request, self.thread, new_reply)
    if err or not comment then
        return err or "Expected Comment but not nil;"
    end
    table.insert(comments, comment)
    self.thread:render_reply_thread()
end

return M
