---@class Entry
---@field value PullRequest
---@field ordinal number
---@field display string

local M = {}

local pull_request_previewer = require("telescope.previewers").new_buffer_previewer({
    title = "Pull request preview",
    ---@param self any
    ---@param entry Entry
    ---@param _ any
    define_preview = function(self, entry, _)
        require("ado.preview").pull_request_preview(self.state.bufnr, entry.value)
    end,
})

---@param entry PullRequest
---@return Entry
local function entry_maker(entry)
    return {
        value = entry,
        display = entry.title,
        ordinal = entry.title,
    }
end

---@param prompt_bufnr number
---@param state_manager StateManager
local function handle_choice(prompt_bufnr, state_manager)
    require("telescope.actions").close(prompt_bufnr)
    ---@type Entry
    local selection = require("telescope.actions.state").get_selected_entry()
    state_manager:set_state_by_choice(selection.value)
    require("ado.activate").activate_pull_request_context(state_manager.state)
end

---Choose and activate selected pull request
---@param state_manager StateManager
function M.choose_and_activate(state_manager)
    require("telescope.pickers")
        .new(require("telescope.themes").get_ivy({}), {
            prompt_title = "Pull requests",
            finder = require("telescope.finders").new_table({
                results = state_manager.pull_requests,
                entry_maker = entry_maker,
            }),
            sorter = require("telescope.config").values.generic_sorter({}),
            previewer = pull_request_previewer,
            attach_mappings = function(prompt_bufnr, _)
                require("telescope.actions").select_default:replace(function()
                    handle_choice(prompt_bufnr, state_manager)
                end)
                return true
            end,
        })
        :find()
end

return M
