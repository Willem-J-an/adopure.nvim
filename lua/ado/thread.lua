local M = {}

local namespace = vim.api.nvim_create_namespace("ado")

---@param state AdoState
---@param bufnr number
---@param comment_reply CommentReply
---@return string|nil err
local function submit_thread_reply(state, bufnr, comment_reply)
    local comments = comment_reply.thread.comments

    ---@type NewComment
    local new_reply = {
        parentCommentId = comments[#comments].id - 1,
        content = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n"),
        commentType = 1,
    }
    local comment, err =
        require("ado.api").create_pull_request_comment_reply(state.active_pull_request, comment_reply.thread, new_reply)
    if err or not comment then
        return err or "Expected Comment but not nil;"
    end
    table.insert(comments, comment)
    require("ado.render").render_reply_thread(namespace, comment_reply.thread)
end

---@param state AdoState
---@param thread_context ThreadContext
---@return PullRequestCommentThreadContext|nil pull_request_thread_context, string|nil err
local function get_pull_request_comment_thread_context(state, thread_context)
    local iteration_changes, err = require("ado.api").get_pull_requests_iteration_changes(
        state.active_pull_request,
        state.active_pull_request_iteration
    )
    if err then
        return nil, err
    end
    for _, change in pairs(iteration_changes) do
        if change.item.path == thread_context.filePath then
            ---@type PullRequestCommentThreadContext
            local comment_thread_context = {
                changeTrackingId = change.changeTrackingId,
                iterationContext = {
                    firstComparingIteration = state.active_pull_request_iteration.id,
                    secondComparingIteration = state.active_pull_request_iteration.id,
                },
            }
            return comment_thread_context, nil
        end
    end
    return nil, "File not changed in this Pull Request;"
end

---@param state AdoState
---@param bufnr number
---@param comment_creation CommentCreate
---@return string|nil err
local function submit_thread(state, bufnr, comment_creation)
    local pull_request_thread_context, get_err =
        get_pull_request_comment_thread_context(state, comment_creation.thread_context)
    if get_err or not pull_request_thread_context then
        return get_err or "Expected PullRequestCommentThreadContext but got nil;"
    end

    ---@type NewThread
    local new_thread = {
        threadContext = comment_creation.thread_context,
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
    local thread, err = require("ado.api").create_pull_request_comment_thread(state.active_pull_request, new_thread)
    if err or not thread then
        return err or "Expected Thread but got nil;"
    end
    table.insert(state.pull_request_threads, thread)
    require("ado.render").render_reply_thread(namespace, thread)
end

---@return number line_start, number col_start, number line_end, number col_end
local function get_selected_position()
    local _, line_start, col_start = unpack(vim.fn.getpos("v"))
    local _, line_end, col_end = unpack(vim.fn.getpos("."))

    local mode = vim.api.nvim_get_mode()["mode"]
    if mode == "V" then
        return line_start - 1, 0, line_end - 1, -1
    end
    if mode == "v" then
        return line_start - 1, col_start - 1, line_end - 1, col_end
    end
    error("Mode not implemented: " .. mode)
end

---Get thread context for left or right file
---@param col_end number
---@param col_start number
---@param line_end number
---@param line_start number
---@return ThreadContext
local function get_thread_context(col_end, col_start, line_end, line_start)
    local file_path = "/" .. vim.fn.expand("%:.")
    if file_path:match("^/diffview://") then
        local left_path = file_path:gsub("^/diffview://.+/.git/[^/]+(.*)$", "%1")
        ---@type ThreadContext
        return {
            filePath = left_path,
            leftFileStart = { line = line_start + 1, offset = col_start + 1 },
            leftFileEnd = { line = line_end + 1, offset = col_end },
            rightFileStart = nil,
            rightFileEnd = nil,
        }
    end
    ---@type ThreadContext
    return {
        filePath = file_path,
        leftFileStart = nil,
        leftFileEnd = nil,
        rightFileStart = { line = line_start + 1, offset = col_start + 1 },
        rightFileEnd = { line = line_end + 1, offset = col_end },
    }
end

function M.new_thread_window(state)
    local line_start, col_start, line_end, col_end = get_selected_position()
    local selection = vim.api.nvim_buf_get_text(0, line_start, col_start, line_end, col_end, {})
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", false, true, true), "nx", false)
    col_end = col_end + 1
    if col_end == 0 then
        col_end = 2147483647
    end
    local thread_context = get_thread_context(col_end, col_start, line_end, line_start)

    local bufnr, mark_id = require("ado.render").render_new_thread(namespace, selection)

    ---@type CommentCreate
    local comment_creation = {
        bufnr = bufnr,
        mark_id = mark_id,
        thread_context = thread_context,
    }
    table.insert(state.comment_creations, comment_creation)
end

---Open thread in window
---@param extmark_id number|nil
function M.open_thread_window(state, extmark_id)
    if not extmark_id then
        local extmarks = require("ado.marker").get_extmarks_at_position(namespace)
        local first_extmark = extmarks[1]
        extmark_id = first_extmark[1]
    end

    ---@type Thread|nil
    local thread_to_open
    for _, pull_request_thread in pairs(state.pull_request_threads) do
        if pull_request_thread.id == extmark_id then
            thread_to_open = pull_request_thread
        end
    end
    if not thread_to_open then
        vim.notify("Did not find thread to open;", 2)
        return
    end
    local bufnr, mark_id = require("ado.render").render_reply_thread(namespace, thread_to_open)
    ---@type CommentReply
    local comment_reply = { bufnr = bufnr, mark_id = mark_id, thread = thread_to_open }
    table.insert(state.comment_replies, comment_reply)
end

---@param bufnr number
---@return CommentCreate|nil
local function _get_comment_creation(state, bufnr)
    for _, comment_creation in pairs(state.comment_creations) do
        if comment_creation.bufnr == bufnr then
            return comment_creation
        end
    end
end

---@param state AdoState
---@param bufnr number
---@return CommentReply|nil
local function _get_comment_reply(state, bufnr)
    for _, comment_reply in pairs(state.comment_replies) do
        if comment_reply.bufnr == bufnr then
            return comment_reply
        end
    end
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

---Update pull request thread status
---@param state AdoState
function M.update_thread_status(state)
    ---@type number
    local bufnr = vim.api.nvim_get_current_buf()
    local comment_reply = _get_comment_reply(state, bufnr)
    if not comment_reply then
        vim.notify("No comment reply found;", 2)
        return
    end

    vim.ui.select(thread_status, { prompt = "Select new status;" }, function(choice)
        if not choice then
            vim.notify("No new status chosen;", 2)
            return
        end

        ---@type Thread
        ---@diagnostic disable-next-line: missing-fields
        local thread = {
            id = comment_reply.thread.id,
            status = choice,
        }
        local updated_thread, err = require("ado.api").update_pull_request_thread(state.active_pull_request, thread)
        if err or not updated_thread then
            error(err or "Expected Thread but not nil;")
        end
        comment_reply.thread.status = updated_thread.status
        require("ado.render").render_reply_thread(namespace, comment_reply.thread)
    end)
end

function M.submit_comment(state)
    ---@type string|nil
    local err
    ---@type number
    local bufnr = vim.api.nvim_get_current_buf()
    local comment_creation = _get_comment_creation(state, bufnr)
    if comment_creation then
        err = submit_thread(state, bufnr, comment_creation)
        if err then
            error(err)
        end
        return
    end

    local comment_reply = _get_comment_reply(state, bufnr)
    if comment_reply then
        err = submit_thread_reply(state, bufnr, comment_reply)
        if err then
            error(err)
        end
        return
    end
    vim.notify("No comment found to create or reply to;", 2)
end

return M
