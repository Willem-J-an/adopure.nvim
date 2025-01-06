local Path = require("plenary.path")
local M = {}
---@mod adopure.thread

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
---@param state adopure.AdoState
---@param col_end number
---@param col_start number
---@param line_end number
---@param line_start number
---@return adopure.ThreadContext
local function get_thread_context(state, col_end, col_start, line_end, line_start)
    local file_path = vim.fn.expand("%:p")
    if file_path:match("^diffview://") then
        local left_path = file_path:gsub("^diffview://.+/.git/[^/]+(.*)$", "%1")
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
        filePath = "/" .. tostring(Path:new(file_path):make_relative(state.root_path)),
        leftFileStart = nil,
        leftFileEnd = nil,
        rightFileStart = { line = line_start + 1, offset = col_start + 1 },
        rightFileEnd = { line = line_end + 1, offset = col_end },
    }
end

---Opens a new comment thread window in the context of the selected text.
---Make a selection to comment on, then call this to open a window.
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
    local thread_context = get_thread_context(state, col_end, col_start, line_end, line_start)

    local bufnr, mark_id = require("adopure.render").render_new_thread(selection)

    local comment_creation = require("adopure.types.comment_create").CommentCreation:new(bufnr, mark_id, thread_context)
    table.insert(state.comment_creations, comment_creation)
end

---@private
---@class adopure.OpenThreadWindowOpts
---@field thread_id number|nil

---@param opts adopure.OpenThreadWindowOpts
---@return number[]
local function _get_extmark_ids(opts)
    if opts.thread_id then
        return { opts.thread_id }
    end
    return vim.iter(require("adopure.marker").get_extmarks_at_position())
        :map(function(extmark)
            return extmark[1]
        end)
        :totable()
end

---Open an existing comment thread in a window.
---Can be called if there is an extmark indicating an available comment thread.
---@param state adopure.AdoState
---@param opts adopure.OpenThreadWindowOpts
function M.open_thread_window(state, opts)
    local extmark_ids = _get_extmark_ids(opts)

    ---@param pull_request_thread adopure.AdoThread|nil
    local function _render_thread_window(pull_request_thread)
        if not pull_request_thread then
            vim.notify("Did not choose thread to open;", 3)
            return
        end
        local bufnr, mark_id = pull_request_thread:render_reply_thread()
        state:add_comment_reply(bufnr, mark_id, pull_request_thread)
    end

    ---@type adopure.AdoThread[]
    local threads_to_open = vim.iter(state.pull_request_threads)
        :filter(function(pull_request_thread) ---@param pull_request_thread adopure.AdoThread
            return vim.iter(extmark_ids):any(function(extmark_id)
                return extmark_id == pull_request_thread.id
            end)
        end)
        :totable()
    if #threads_to_open == 0 then
        vim.notify("Did not find thread to open;", 3)
        return
    end
    if #threads_to_open == 1 then
        _render_thread_window(threads_to_open[1])
        return
    end

    vim.ui.select(threads_to_open, {
        prompt = "Select pull request thread to open;",
        format_item = require("adopure.utils").pull_request_thread_title,
    }, _render_thread_window)
end

---Update pull request thread status.
---Will prompt the user to supply the requested new state.
---Can be called in an existing thread window.
---@deprecated Migrate to: adopure.AdoState:update_thread({target="update_status"})
---@param state adopure.AdoState
---@param _ table
function M.update_thread_status(state, _)
    ---@type number
    local bufnr = vim.api.nvim_get_current_buf()
    local comment_reply = state:get_comment_reply(bufnr)
    if comment_reply then
        state:update_thread({ target = "update_status" })
        return
    end
    vim.notify("No comment found to update;", 3)
end

---@param state adopure.AdoState
---@param _ table
---@deprecated Migrate to adopure.AdoState:submit_comment(_)
function M.submit_comment(state, _)
    state:submit_comment(_)
end

return M
