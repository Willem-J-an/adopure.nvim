---@class PullRequestEntry
---@field value PullRequest
---@field ordinal number
---@field display string

local M = {}

---@return integer autocmd_id
function M.create_auto_wrap_preview()
    return vim.api.nvim_create_autocmd("User", {
        pattern = "TelescopePreviewerLoaded",
        callback = function(_)
            vim.wo.wrap = true
        end,
    })
end

local pull_request_previewer = require("telescope.previewers").new_buffer_previewer({
    title = "Pull request preview",
    ---@param self any
    ---@param entry PullRequestEntry
    ---@param _ any
    define_preview = function(self, entry, _)
        require("ado.previews.pull_request").pull_request_preview(self.state.bufnr, entry.value)
    end,
})
---@param entry PullRequest
---@return PullRequestEntry
local function entry_maker(entry)
    ---@type string|nil
    local votes = vim.iter(entry.reviewers)
        :filter(function(reviewer)
            return reviewer.vote ~= 0
        end)
        :map(function(reviewer)
            local Review = require("ado.review")
            local vote = Review.get_vote_from_value(reviewer.vote)
            return Review.vote_icons[vote]
        end)
        :join(" ")
    if votes == "" then
        votes = nil
    end
    return {
        value = entry,
        display = entry.title .. " - " .. (votes or "󰇘 "),
        ordinal = entry.title,
    }
end

---@param prompt_bufnr number
---@param state_manager StateManager
local function handle_choice(prompt_bufnr, state_manager)
    require("telescope.actions").close(prompt_bufnr)
    ---@type PullRequestEntry
    local selection = require("telescope.actions.state").get_selected_entry()
    state_manager:set_state_by_choice(selection.value)
    require("ado.activate").activate_pull_request_context(state_manager.state)
end

---Choose and activate selected pull request
---@param state_manager StateManager
function M.choose_and_activate(state_manager)
    local wrap_preview_id = M.create_auto_wrap_preview()
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
                    vim.api.nvim_del_autocmd(wrap_preview_id)
                end)
                return true
            end,
        })
        :find()
end

return M
