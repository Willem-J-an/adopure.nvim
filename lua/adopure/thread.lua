local M = {}

---@param state adopure.AdoState
---@param bufnr number
---@param comment_reply adopure.CommentReply
---@return string|nil err
local function submit_thread_reply(state, bufnr, comment_reply)
    local comments = comment_reply.thread.comments

    ---@type adopure.NewComment
    local new_reply = {
        parentCommentId = comments[#comments].id - 1,
        content = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n"),
        commentType = 1,
    }
    local comment, err = require("adopure.api").create_pull_request_comment_reply(
        state.active_pull_request,
        comment_reply.thread,
        new_reply
    )
    if err or not comment then
        return err or "Expected Comment but not nil;"
    end
    table.insert(comments, comment)
    require("adopure.render").render_reply_thread(comment_reply.thread)
end

---@param state adopure.AdoState
---@param thread_context adopure.ThreadContext
---@return adopure.PullRequestCommentThreadContext|nil pull_request_thread_context, string|nil err
local function get_pull_request_comment_thread_context(state, thread_context)
    local iteration_changes, err = require("adopure.api").get_pull_requests_iteration_changes(
        state.active_pull_request,
        state.active_pull_request_iteration
    )
    if err then
        return nil, err
    end
    for _, change in pairs(iteration_changes) do
        if change.item.path == thread_context.filePath then
            ---@type adopure.PullRequestCommentThreadContext
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

---@param bufnr number
---@param mark_id number
---@param state adopure.AdoState
---@param thread_to_open adopure.Thread
local function add_comment_reply(bufnr, mark_id, state, thread_to_open)
    ---@type adopure.CommentReply
    local comment_reply = { bufnr = bufnr, mark_id = mark_id, thread = thread_to_open }
    table.insert(state.comment_replies, comment_reply)
end

---@param state adopure.AdoState
---@param bufnr number
---@param comment_creation adopure.CommentCreate
---@return string|nil err
local function submit_thread(state, bufnr, comment_creation)
    local pull_request_thread_context, get_err =
        get_pull_request_comment_thread_context(state, comment_creation.thread_context)
    if get_err or not pull_request_thread_context then
        return get_err or "Expected PullRequestCommentThreadContext but got nil;"
    end

    ---@type adopure.NewThread
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
    local thread, err = require("adopure.api").create_pull_request_comment_thread(state.active_pull_request, new_thread)
    if err or not thread then
        return err or "Expected Thread but got nil;"
    end
    table.insert(state.pull_request_threads, thread)
    local mark_id
    bufnr, mark_id = require("adopure.render").render_reply_thread(thread)
    add_comment_reply(bufnr, mark_id, state, thread)
end

---@return number line_start, number col_start, number line_end, number col_end
local function get_selected_position()
    local mode = vim.api.nvim_get_mode()["mode"]
    local pos_by_mode = { "'<", "'>" }
    if vim.tbl_contains({ "v", "V" }, mode) then
        pos_by_mode = { "v", "." }
    end
    local _, line_start, col_start = unpack(vim.fn.getpos(pos_by_mode[1]))
    local _, line_end, col_end = unpack(vim.fn.getpos(pos_by_mode[2]))

    if col_start == col_end or (col_start == 1 and col_end == 2147483647) then
        return line_start - 1, 0, line_end - 1, -1
    end
    return line_start - 1, col_start - 1, line_end - 1, col_end
end

---Get thread context for left or right file
---@param col_end number
---@param col_start number
---@param line_end number
---@param line_start number
---@return adopure.ThreadContext
local function get_thread_context(col_end, col_start, line_end, line_start)
    local file_path = "/" .. vim.fn.expand("%:.")
    if file_path:match("^/diffview://") then
        local left_path = file_path:gsub("^/diffview://.+/.git/[^/]+(.*)$", "%1")
        ---@type adopure.ThreadContext
        return {
            filePath = left_path,
            leftFileStart = { line = line_start + 1, offset = col_start + 1 },
            leftFileEnd = { line = line_end + 1, offset = col_end },
            rightFileStart = nil,
            rightFileEnd = nil,
        }
    end
    ---@type adopure.ThreadContext
    return {
        filePath = file_path,
        leftFileStart = nil,
        leftFileEnd = nil,
        rightFileStart = { line = line_start + 1, offset = col_start + 1 },
        rightFileEnd = { line = line_end + 1, offset = col_end },
    }
end

---@param state adopure.AdoState
---@param _ table
function M.new_thread_window(state, _)
    local line_start, col_start, line_end, col_end = get_selected_position()
    local selection = vim.api.nvim_buf_get_text(0, line_start, col_start, line_end, col_end, {})
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", false, true, true), "nx", false)
    col_end = col_end + 1
    if col_end == 0 then
        col_end = 2147483647
    end
    local thread_context = get_thread_context(col_end, col_start, line_end, line_start)

    local bufnr, mark_id = require("adopure.render").render_new_thread(selection)

    ---@type adopure.CommentCreate
    local comment_creation = {
        bufnr = bufnr,
        mark_id = mark_id,
        thread_context = thread_context,
    }
    table.insert(state.comment_creations, comment_creation)
end

---@class adopure.OpenThreadWindowOpts
---@field thread_id number|nil

---Open thread in window
---@param opts adopure.OpenThreadWindowOpts
function M.open_thread_window(state, opts)
    local extmark_id = opts.thread_id
    if not extmark_id then
        local extmarks = require("adopure.marker").get_extmarks_at_position()
        local first_extmark = extmarks[1]
        extmark_id = first_extmark[1]
    end

    ---@type adopure.Thread|nil
    local thread_to_open
    for _, pull_request_thread in pairs(state.pull_request_threads) do
        if pull_request_thread.id == extmark_id then
            thread_to_open = pull_request_thread
        end
    end
    if not thread_to_open then
        vim.notify("Did not find thread to open;", 3)
        return
    end
    local bufnr, mark_id = require("adopure.render").render_reply_thread(thread_to_open)
    add_comment_reply(bufnr, mark_id, state, thread_to_open)
end

---@param bufnr number
---@return adopure.CommentCreate|nil
local function _get_comment_creation(state, bufnr)
    for _, comment_creation in pairs(state.comment_creations) do
        if comment_creation.bufnr == bufnr then
            return comment_creation
        end
    end
end

---@param state adopure.AdoState
---@param bufnr number
---@return adopure.CommentReply|nil
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
---@param state adopure.AdoState
---@param _ table
function M.update_thread_status(state, _)
    ---@type number
    local bufnr = vim.api.nvim_get_current_buf()
    local comment_reply = _get_comment_reply(state, bufnr)
    if not comment_reply then
        vim.notify("No comment reply found;", 3)
        return
    end

    vim.ui.select(thread_status, { prompt = "Select new status;" }, function(choice)
        if not choice then
            vim.notify("No new status chosen;", 3)
            return
        end

        ---@type adopure.Thread
        local thread = { ---@diagnostic disable-line: missing-fields
            id = comment_reply.thread.id,
            status = choice,
        }
        local updated_thread, err = require("adopure.api").update_pull_request_thread(state.active_pull_request, thread)
        if err or not updated_thread then
            error(err or "Expected Thread but not nil;")
        end
        comment_reply.thread.status = updated_thread.status
        require("adopure.render").render_reply_thread(comment_reply.thread)
    end)
end

---@param state adopure.AdoState
---@param _ table
function M.submit_comment(state, _)
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
        state.comment_creations = vim.iter(state.comment_creations)
            :filter(function(state_comment_creation) ---@param state_comment_creation adopure.CommentCreate
                return comment_creation.bufnr ~= state_comment_creation.bufnr
            end)
            :totable()
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
    vim.notify("No comment found to create or reply to;", 3)
end

return M
