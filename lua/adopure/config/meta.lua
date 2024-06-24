---@mod adopure.config.meta

---The plugin is configured by setting vim.g.adopure.
---
---`@type adopure.Config
---vim.g.adopure = { pat_token = secret_value }
---
---
---@class adopure.Highlights
---@field active? string Highlight for lines with active comments.
---@field active_sign? string Highlight for sign indicating active comments.
---@field inactive? string Highlight for lines with inactive comments.
---@field inactive_sign? string Highlight for sign indicating in active comments.

---@class adopure.Config
---@field pat_token? string Personal Access Token to acess Azure DevOps.
---@field hl_groups? adopure.Highlights Highlight groups to apply.
---@field preferred_remotes? string[] List with preferred remotes to extract Azure DevOps context from.

local config = {}

---@type adopure.Config | fun():adopure.Config | nil
vim.g.adopure = vim.g.adopure ---@diagnostic disable-line: inject-field

return config
