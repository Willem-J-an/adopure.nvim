---@class ThreadEntry
---@field value Thread
---@field ordinal number
---@field display string

local M = {}
local thread_previewer = require("telescope.previewers").new_buffer_previewer({
    title = "Thread preview",
    ---@param self any
    ---@param entry ThreadEntry
    ---@param _ any
    define_preview = function(self, entry, _)
        require("ado.previews.thread").thread_preview(self.state.bufnr, entry.value)
    end,
})

---@param entry Thread
---@return ThreadEntry
local function entry_maker(entry)
    return {
        value = entry,
        display = entry.comments[1].content,
        ordinal = entry.comments[1].content,
    }
end

---@param prompt_bufnr number
local function handle_choice(prompt_bufnr)
    require("telescope.actions").close(prompt_bufnr)
    ---@type ThreadEntry
    local selection = require("telescope.actions.state").get_selected_entry()
    vim.notify(vim.inspect(selection))
    -- Do something with selection
end

---Choose thread
---@param state AdoState
function M.choose_thread(state)
    local wrap_preview_id = require("ado.pickers.pull_request").create_auto_wrap_preview()
    require("telescope.pickers")
        .new(require("telescope.themes").get_ivy({}), {
            prompt_title = "Threads",
            finder = require("telescope.finders").new_table({
                results = state.pull_request_threads,
                entry_maker = entry_maker,
            }),
            sorter = require("telescope.config").values.generic_sorter({}),
            previewer = thread_previewer,
            attach_mappings = function(prompt_bufnr, _)
                require("telescope.actions").select_default:replace(function()
                    handle_choice(prompt_bufnr)
                    vim.api.nvim_del_autocmd(wrap_preview_id)
                end)
                return true
            end,
        })
        :find()
end

return M
