---@class adopure.Config
---@field pat_token? string

local config = {}

---@type adopure.Config | fun():adopure.Config | nil
vim.g.adopure = vim.g.adopure

return config
