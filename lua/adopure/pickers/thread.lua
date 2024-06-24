---@mod adopure.pickers.thread
---@diagnostic disable: undefined-doc-name

---@private
---@class adopure.ThreadEntry
---@field value adopure.Thread
---@field ordinal number
---@field display string

local M = {}
local thread_previewer = require("telescope.previewers").new_buffer_previewer({
    title = "Thread preview",
    ---@param self any
    ---@param entry adopure.ThreadEntry
    ---@param _ any
    define_preview = function(self, entry, _)
        require("adopure.previews.thread").thread_preview(self.state.bufnr, entry.value)
    end,
})

---@param entry adopure.Thread
---@return adopure.ThreadEntry
local function entry_maker(entry)
    return {
        value = entry,
        display = entry.comments[1].content,
        ordinal = entry.comments[1].content,
    }
end

---@param file_path string
---@param thread_context adopure.ThreadContext
local function open_scroll(file_path, thread_context)
    if vim.fn.filereadable(file_path) == 0 then
        vim.notify("No such file: " .. file_path, 3)
        return
    end
    vim.cmd(":edit " .. file_path)
    if thread_context.rightFileStart then
        vim.api.nvim_win_set_cursor(0, { thread_context.rightFileStart.line, thread_context.rightFileStart.offset })
    end
end

---@param prompt_bufnr number
---@param state adopure.AdoState
local function handle_choice(prompt_bufnr, state)
    require("telescope.actions").close(prompt_bufnr)
    ---@type adopure.ThreadEntry
    local selection = require("telescope.actions.state").get_selected_entry()
    local context = selection.value["threadContext"]
    if context == vim.NIL or not context then
        return
    end
    local file_path = string.sub(context.filePath, 2)
    open_scroll(file_path, context)
    ---@type adopure.OpenThreadWindowOpts
    local open_thread_window_opts = { thread_id = selection.value.id }
    require("adopure.thread").open_thread_window(state, open_thread_window_opts)
end

local thread_filters = {
    ---@param thread adopure.Thread
    hide_system = function(thread)
        return thread.comments[1].commentType == "text"
    end,
    ---@param thread adopure.Thread
    hide_closed = function(thread)
        return thread.status == "active" or thread.status == "pending"
    end,
}

---Parameters for the thread picker.
---@class adopure.ChooseThreadOpts
---Supports following filters:
---*hide_system*: Hides system threads in the picker.
---*hide_closed*: Hides closed threads in the picker.
---@field thread_filters string[]

---@param thread_iter Iter
---@param thread_filter string
---@return Iter thread_iter
local function apply_filter(thread_iter, thread_filter)
    if not thread_filters[thread_filter] then
        vim.notify("Invalid thread filter provided: " .. thread_filter, 3)
        return thread_iter
    end
    return thread_iter:filter(thread_filters[thread_filter]) ---@diagnostic disable-line: undefined-field
end

---@param pull_request_threads adopure.Thread[]
---@param opts adopure.ChooseThreadOpts
---@return adopure.Thread[] pull_request_threads
local function filter_pull_request_threads(pull_request_threads, opts)
    if not opts.thread_filters then
        return pull_request_threads
    end
    local thread_iter = vim.iter(pull_request_threads)
    for _, thread_filter in ipairs(opts.thread_filters) do
        thread_iter = apply_filter(thread_iter, thread_filter)
    end
    return thread_iter:totable() ---@diagnostic disable-line: undefined-field
end

---Choose a comment thread to jump to and open the related comment thread window.
---@param state adopure.AdoState
---@param opts adopure.ChooseThreadOpts
function M.choose_thread(state, opts)
    local wrap_preview_id = require("adopure.pickers.pull_request").create_auto_wrap_preview()
    require("telescope.pickers")
        .new(require("telescope.themes").get_ivy({}), {
            prompt_title = "Threads",
            finder = require("telescope.finders").new_table({
                results = filter_pull_request_threads(state.pull_request_threads, opts),
                entry_maker = entry_maker,
            }),
            sorter = require("telescope.config").values.generic_sorter({}),
            previewer = thread_previewer,
            attach_mappings = function(prompt_bufnr, _)
                require("telescope.actions").select_default:replace(function()
                    handle_choice(prompt_bufnr, state)
                    vim.api.nvim_del_autocmd(wrap_preview_id)
                end)
                return true
            end,
        })
        :find()
end

return M
