---@class adopure.Highlights
---@field active? string
---@field active_sign? string
---@field inactive? string
---@field inactive_sign? string

---@class adopure.Config
---@field pat_token? string
---@field hl_groups? adopure.Highlights
---@field preferred_remotes? string[]

local config = {}

---@type adopure.Config | fun():adopure.Config | nil
vim.g.adopure = vim.g.adopure ---@diagnostic disable-line: inject-field

return config
