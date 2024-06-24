---@mod adopure.config.meta
---@brief [[
---The plugin is configured by assigning an adopure.Config to vim.g.adopure.
--->lua
--- vim.g.adopure = {}
---<
---@brief ]]
---
---@class adopure.Highlights
---@field active? string Highlight for lines with active comments.
---@field active_sign? string Highlight for sign indicating active comments.
---@field inactive? string Highlight for lines with inactive comments.
---@field inactive_sign? string Highlight for sign indicating in active comments.

---@class adopure.Config
---If not provided, attempt to use AZURE_DEVOPS_EXT_PAT environment variable.
---If no environment variable is set, and no config is provided, the plugin will not work.
---The plugin offers no mechanism to securely load secrets.
---If you have a cli command that will produce the secret, consider doing something like this:
--->lua
--- local nio = require("nio")
--- nio.run(function()
---     local secret_job = nio.process.run({ cmd = "pass", args = { "show", secret_name} })
---     vim.g.adopure = { pat_token = secret_job.stdout.read():sub(1, -2) }
--- end)
---<
---Alternatively, you can set it as environment variable.
---
---
---@field pat_token? string Personal Access Token to acess Azure DevOps.
---@field hl_groups? adopure.Highlights Highlight groups to apply.
---List with preferred remotes to extract Azure DevOps context from.
---Remotes are elected among the following options:
---1. Any remote in this list can be picked, non-deterministically.
---2. Any Azure DevOps remote.
---3. Any remote. If it's not an Azure DevOps remote, the plugin will not work.
---@field preferred_remotes? string[]

local config = {}

---@type adopure.Config | fun():adopure.Config | nil
vim.g.adopure = vim.g.adopure

return config
